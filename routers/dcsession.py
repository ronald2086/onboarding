import httpx
from fastapi import Depends, HTTPException
from sqlalchemy import desc
from sqlalchemy.orm import Session
from app import models
from auth.auth_bearer import JWTBearer
from app.database import get_db
from fastapi import APIRouter

router = APIRouter(
    tags=["Data Collection"],
    dependencies=[Depends(JWTBearer())]
)


@router.get("/getSessions/{username}")
async def getSessions(username: str, db: Session = Depends(get_db)):
    user_check = db.query(models.DCSessions.id).filter(models.DCSessions.username == username).first()

    if user_check is None:
        raise HTTPException(
            status_code=404,
            detail=f" The Session with given username :{username} does not exists..!"
        )
    users_sessions = db.query(models.DCSessions.username).filter(models.DCSessions.username.like(username)).all()
    return users_sessions


@router.delete("/deleteSession/{dcsession_id}")
async def delete_session(dcsession_id: int, db: Session = Depends(get_db)):
    session_check = db.query(models.DCSessions).filter(models.DCSessions.id == dcsession_id).first()

    if session_check is None:
        raise HTTPException(
            status_code=404,
            detail=f" The session with id: {dcsession_id} does not exists..!"
        )

    db.query(models.DCSessions).filter(models.DCSessions.id == dcsession_id).delete()
    db.commit()
    return f" The session with given id  {dcsession_id}, has been deleted successfully..!"


def format_tag_ids(tag_ids):
    if tag_ids:
        tag_ids = tag_ids.replace(" ", "")
        tag_ids = tag_ids[:-1] if tag_ids[-1] == "," else tag_ids
        tag_ids = tag_ids.lower()

    return tag_ids


@router.get("/initializeSession/{dataServer_id}/{username}/{org_id}/{floor_id}/{zone_room_id}/{tag_ids}/{session_name}")
async def initializeSession(dataServer_id: int, username: str, org_id: int,
                            floor_id: int, zone_room_id: int, tag_ids: str, session_name: str,
                            db: Session = Depends(get_db)):
    org_name = db.query(models.Org.Manage_Org_Name).filter(models.Org.id == org_id).one_or_none()
    org_name = org_name[0]

    if org_name is None:
        raise HTTPException(
            detail=f" The organization with given id: {org_id} does not exists..!",
            status_code=404
        )

    floor_name = db.query(models.Floor.Manage_Floor_Name).filter(models.Floor.id == floor_id).one_or_none()

    if floor_name is None:
        raise HTTPException(
            detail=f" The organization with given floor id: {floor_id} does not exists..!",
            status_code=404

        )

    server_address = db.query(models.DataServer.address).filter(models.DataServer.id == dataServer_id).one_or_none()

    if server_address is None:
        raise HTTPException(
            detail=f" The server with given  server id: {dataServer_id} does not exists..!",
            status_code=404
        )
    session_model = models.DCSessions()
    session_model.dataServer_id = dataServer_id
    session_model.username = username
    session_model.org_id = org_id
    session_model.floor_id = floor_id
    session_model.zone_room_id = zone_room_id
    session_model.tag_ids = format_tag_ids(tag_ids)
    session_model.session_name = session_name

    db.add(session_model)
    db.commit()

    dcsession_id = db.query(models.DCSessions).filter(models.DCSessions.id).order_by(desc(models.DCSessions.id)).first()
    dcsession_name = db.query(models.DCSessions.session_name).filter(models.DCSessions.id == dcsession_id.id).first()
    dcsession_id = dcsession_name[0]
    print(dcsession_id)

    url = f"http://{server_address.address}/initialize-session".format(server_address=server_address)

    payload = {
        "org_name": org_name,
        "session_uid": dcsession_id,
        "tag_ids": format_tag_ids(tag_ids),
        "floor": floor_name.Manage_Floor_Name,
    }
    print(payload)

    async def task():
        async with httpx.AsyncClient() as client:
            result = await client.get(url, params=payload)
            print(result.text)
            print(result.url)
            tb_data = result.json()["table_data"]
            return tb_data

    table_data = await task()

    return {f'session_id': session_model.id}, table_data


@router.get("/startDataCollection/{dcsession_id}")
async def startDataCollection(org_id: int, dcsession_id: int, db: Session = Depends(get_db)):
    dcsession_id = db.query(models.DCSessions).filter(models.DCSessions.id == dcsession_id).one_or_none()

    if dcsession_id is None:
        raise HTTPException(
            detail=f" The session with given  session id: {dcsession_id} does not exists..!",
            status_code=404
        )
    org_name = db.query(models.Org.Manage_Org_Name).filter(models.Org.id == org_id).one_or_none()
    org_name = org_name[0]

    if org_name is None:
        raise HTTPException(
            detail=f" The organization with given id: {org_id} does not exists..!",
            status_code=404
        )

    current_zone = db.query(models.DCSessions.zone_room_id).filter(
        models.DCSessions.id == dcsession_id.id).first()
    current_zone = current_zone[0]
    current_zone_name = db.query(models.ZoneRoom.Ext_Zone_Room_Name).filter(models.ZoneRoom.id == current_zone).first()
    current_zone = current_zone_name[0]
    dcsession_name = db.query(models.DCSessions.session_name).filter(models.DCSessions.id == dcsession_id.id).first()
    dcsession_id = dcsession_name[0]
    print(org_name)
    print(dcsession_id)
    print(current_zone)

    payload = {
        "org_name": org_name,
        "session_uid": dcsession_id,
        "current_zone": current_zone,
    }
    print(payload)

    server_address = db.query(models.DataServer).join(models.DCSessions).filter(
        models.DCSessions.org_id == org_id).first()

    url = f"http://{server_address.address}/start-data-collection".format(server_address=server_address)

    async def task():
        async with httpx.AsyncClient() as client:
            try:
                result = await client.get(url, params=payload)
                print(result.url)
                print(result.text)
                tb_data = result.json()
            except httpx.HTTPError:
                print(f"Error while requesting {url}.")

            return tb_data

    table_data = await task()

    return table_data


@router.get("/checkDataCollection/{dcsession_id}")
async def checkDataCollection(org_id: int, dcsession_id: int, db: Session = Depends(get_db)):
    dcsession_id = db.query(models.DCSessions).filter(models.DCSessions.id == dcsession_id).one_or_none()

    if dcsession_id is None:
        raise HTTPException(
            detail=f" The session with given  session id: {dcsession_id} does not exists..!",
            status_code=404
        )
    dcsession_name = db.query(models.DCSessions.session_name).filter(models.DCSessions.id == dcsession_id.id).first()
    dcsession_id = dcsession_name[0]

    org_name = db.query(models.Org.Manage_Org_Name).filter(models.Org.id == org_id).one_or_none()
    org_name = org_name[0]

    if org_name is None:
        raise HTTPException(
            detail=f" The organization with given id: {org_id} does not exists..!",
            status_code=404
        )

    payload = {
        "org_name": org_name,
        "session_uid": dcsession_id,
    }
    print(payload)
    server_address = db.query(models.DataServer).join(models.DCSessions).filter(
        models.DCSessions.org_id == org_id).first()

    url = f"http://{server_address.address}/check-data-collection".format(server_address=server_address)

    async def task():
        async with httpx.AsyncClient() as client:
            try:
                result = await client.get(url, params=payload)
                print(result.text)
                print(result.url)
                tb_data = result.json()["table_data"]
            except httpx.HTTPError:
                print(f"Error while requesting {url}.")

            return tb_data

    table_data = await task()

    return table_data


@router.get("/stopDataCollection/{dcsession_id}")
async def stopDataCollection(org_id: str, dcsession_id: int, db: Session = Depends(get_db)):
    dcsession_id = db.query(models.DCSessions).filter(models.DCSessions.id == dcsession_id).one_or_none()

    if dcsession_id is None:
        raise HTTPException(
            detail=f" The session with given  session id: {dcsession_id} does not exists..!",
            status_code=404
        )
    dcsession_name = db.query(models.DCSessions.session_name).filter(models.DCSessions.id == dcsession_id.id).first()
    dcsession_id = dcsession_name[0]

    org_name = db.query(models.Org.Manage_Org_Name).filter(models.Org.id == org_id).one_or_none()
    org_name = org_name[0]

    if org_name is None:
        raise HTTPException(
            detail=f" The organization with given id: {org_id} does not exists..!",
            status_code=404
        )

    payload = {
        "org_name": org_name,
        "session_uid": dcsession_id,
    }
    print(payload)
    server_address = db.query(models.DataServer).join(models.DCSessions).filter(
        models.DCSessions.org_id == org_id).first()

    url = f"http://{server_address.address}/stop-data-collection".format(server_address=server_address)

    async def task():
        async with httpx.AsyncClient() as client:
            try:
                result = await client.get(url, params=payload)
                print(result.url)
                print(result.text)
                print(result.json())
                tb_data = result.json()["table_data"]
            except httpx.HTTPError:
                print(f"Error while requesting {url}.")

            return tb_data

    table_data = await task()

    return table_data
