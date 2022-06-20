from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session

import app
from app.database import get_db
from app.models import UserTags
from app.schemas import UserTags
from auth.auth_bearer import JWTBearer
from app import models

from fastapi import APIRouter

router = APIRouter(
    prefix="/user",
    tags=["User Tags"],
    dependencies=[Depends(JWTBearer())]
)


@router.get("/{username}/getAllTags")
def get_all_tags(username: str, db: Session = Depends(get_db)):
    """
        Get all the tags for given user.
    """
    username_check = db.query(models.UserTags).filter(models.UserTags.username == username).first()

    if username_check is None:
        raise HTTPException(
            status_code=404,
            detail=f" The user with given  username : {username} does not exist..!"
        )

    user_tags = db.query(models.UserTags.tag_name).filter(models.UserTags.username.like(username)).all()

    return user_tags


@router.post("/{username}/addTag")
def add_new_tag(username: str, tag: str, db: Session = Depends(get_db)):
    """
            Add a tag to given user.
    """
    username_check = db.query(models.User.id).filter(models.User.username == username).one_or_none()
    username_check = username_check[0]

    if username_check is None:
        raise HTTPException(
            status_code=404,
            detail=f"The user with given  username: {username} does not exist...!"
        )

    user_tag_model = models.UserTags()

    user_tag_model.username = username
    user_tag_model.tag_name = tag
    user_tag_model.user_id = username_check

    db.add(user_tag_model)
    db.commit()

    return f"Tag {tag} is added to {username} successfully...!"


'''
@router.put("/{username}/updateTag/{tag}")      # make changes in the api logic as per tag names
def update_user_tag_id(username: str, tag: str, user_tag: app.schemas.UserTags, db: Session = Depends(get_db)):
    user_tag_check = db.query(models.UserTags).filter(models.UserTags.username == username,
                                                      models.UserTags.tag_name == tag).first()

    if user_tag_check is None:
        raise HTTPException(
            status_code=404,
            detail=f"The user: {username} do not have given tag {tag} ...!"
        )

    else:
        user_tag_check.tag_name = user_tag.tag_name

    db.add(user_tag_check)
    db.commit()

    return f'{user_tag} is added to user {username} successfully...!'
'''


@router.delete("/{username}/deleteTag/{tag}")
def delete_user_tag(username: str, tag: str, db: Session = Depends(get_db)):
    """
        Delete a tag from a user.
    """
    user_tag_check = db.query(models.UserTags).filter(models.UserTags.username == username,
                                                      models.UserTags.tag_name == tag).first()

    if user_tag_check is None:
        raise HTTPException(
            status_code=404,
            detail=f"The user: {username} with tag_id: {tag} does not exist...!"
        )

    db.query(models.UserTags).filter(models.UserTags.tag_name == tag).delete()
    db.commit()
    return f"The user: {username} with given tag name: {tag}, has been deleted successfully...!"

