from fastapi import Body, Depends, HTTPException
from sqlalchemy import exc
from sqlalchemy.orm import Session
from app.database import get_db
from app import models
from app.schemas import UserSchema,SetUserCredentialsSchema, ValidateCredentialSchema
from auth.auth_handler import signJWT
from fastapi import APIRouter

router = APIRouter(
                    prefix="/user",
                    tags=["User"],
                 )


@router.get("/")
def read_users(db: Session = Depends(get_db)):
    return db.query(models.User).all()


@router.post("/")
async def create_new_user(user: UserSchema, db: Session = Depends(get_db)):
    new_user = models.User()
    new_user.name = user.name
    new_user.username = user.username
    new_user.pwd_hash = user.pwd_hash
    new_user.role = user.role

    try:
        db.add(new_user)
        db.commit()
        return f' New user added successfully..!'
    except exc.IntegrityError:
        db.rollback()
        return f" The user with given username already exists..!"


@router.get("/getUserCredentials")
def get_user_credentials(username: str, db: Session = Depends(get_db)):
    user_check = db.query(models.User).filter(models.User.username == username)

    if user_check is None:
        raise HTTPException(
            detail=f" User with given username : {username} does not exists..!",
            status_code=404
        )
    get_cred = db.query(models.User.username, models.User.id, models.User.pwd_hash, models.User.role, models.User.name) \
        .filter(models.User.username == username).all()
    return get_cred


@router.put("/setUserCredentials")
async def set_user_credentials(username: str, pwd_hash: str, user: SetUserCredentialsSchema,
                               db: Session = Depends(get_db)):
    set_user = db.query(models.User).filter(models.User.username == username).first()

    if set_user is None:
        raise HTTPException(
            detail=f" User with given username : {username} does not exists..!",
            status_code=404
        )

    check_pwd = db.query(models.User).filter(pwd_hash == models.User.pwd_hash).first()

    if not check_pwd:
        set_user.name = user.name
        set_user.pwd_hash = user.pwd_hash
        set_user.role = user.role
    else:
        return f' User is already having password..!'

    db.add(set_user)
    db.commit()

    return user


@router.post("/{username}/validateCredential/{hash}")
async def user_validate(user: ValidateCredentialSchema = Body(...), db: Session = Depends(get_db)):
    def check_user(data: ValidateCredentialSchema):
        user_check = db.query(models.User).filter(models.User.username == data.username,
                                                  models.User.pwd_hash == data.pwd_hash).first()
        if not user_check:
            return False
        return True

    if check_user(user):
        return signJWT(user.username)
    return {
        "error": "Invalid pwd_hash submitted...!"
    }
