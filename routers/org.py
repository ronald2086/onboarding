from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import OrgBase,FloorBase,ZoneRoomBase,DataServerBase
from auth.auth_bearer import JWTBearer
from app import models, schemas

from fastapi import APIRouter

router = APIRouter(
                prefix="/org",
                tags=["Org"],
                dependencies=[Depends(JWTBearer())]
                )


@router.get("/")
def get_org(db: Session = Depends(get_db)):
    return db.query(models.Org).all()


@router.post("/", response_model=schemas.OrgBase)
def create_org(org: OrgBase, db: Session = Depends(get_db)):
    org_model = models.Org()
    org_model.Ext_Provider = org.Ext_Provider
    org_model.Ext_Provider_Key = org.Ext_Provider_Key
    org_model.Ext_Provider_URL = org.Ext_Provider_URL
    org_model.Ext_Provider_UserName = org.Ext_Provider_UserName
    org_model.Manage_API_Key = org.Manage_API_Key
    org_model.Manage_Org_Id = org.Manage_Org_Id
    org_model.Manage_Org_Name = org.Manage_Org_Name
    org_model.Manage_URL = org.Manage_URL
    org_model.Manage_UserName = org.Manage_UserName

    db.add(org_model)
    db.commit()
    db.refresh(org_model)
    return org


@router.get("/{org_id}/getDataServers")
def get_data_server(org_id: int, db: Session = Depends(get_db)):
    org_check = db.query(models.DataServer).filter(models.DataServer.org_id == org_id).first()

    if org_check is None:
        raise HTTPException(
            status_code=404,
            detail=f" The Data server with given id :{org_id} does not exists..!"
        )
    get_server = db.query(models.DataServer.name, models.DataServer.address)\
        .filter(models.DataServer.org_id == org_id).all()

    return get_server


@router.post("/{org_id}/addDataServer", response_model=schemas.DataServerBase)
def add_data_server(org_id: int, dataserver: DataServerBase, db: Session = Depends(get_db)):
    add_server = models.DataServer()

    add_server.name = dataserver.name
    add_server.address = dataserver.address
    add_server.org_id = org_id

    db.add(add_server)
    db.commit()

    return dataserver


@router.delete("/deleteOrg/{org_id}")
async def delete_org(org_id: int, db: Session = Depends(get_db)):
    book_model = db.query(models.Org).filter(models.Org.id == org_id).first()

    if book_model is None:
        raise HTTPException(
            status_code=404,
            detail=f" The org with ID {org_id} Does not exists"
        )

    db.query(models.Org).filter(models.Org.id == org_id).delete()
    db.commit()
    return f" The Org with ID {org_id}, has been deleted successfully..!"


@router.get("/{org_id}/getFloor")
async def get_floor(org_id: int, db: Session = Depends(get_db)):
    org_floor = db.query(models.Floor).filter(
        models.Floor.org_id == org_id).all()

    if org_floor is None:
        raise HTTPException(
            status_code=404,
            detail=f" The Org with given id :{org_id} does not exists..!"
        )

    return org_floor


@router.post("/{org_id}/createFloor")
async def create_floor(org_id: int, floor: FloorBase, db: Session = Depends(get_db)):
    floor_model = models.Floor()

    floor_model.Ext_Building_Id = floor.Ext_Building_Id
    floor_model.Ext_Floor_Id = floor.Ext_Floor_Id
    floor_model.Manage_Building_Id = floor.Manage_Building_Id
    floor_model.Manage_Building_Name = floor.Manage_Building_Name
    floor_model.Manage_Floor_Id = floor.Manage_Floor_Id
    floor_model.Manage_Floor_Name = floor.Manage_Floor_Name
    floor_model.Manage_Org_Id = floor.Manage_Org_Id
    floor_model.Manage_Site_Id = floor.Manage_Site_Id
    floor_model.Manage_Site_Name = floor.Manage_Site_Name
    floor_model.org_id = org_id

    db.add(floor_model)
    db.commit()
    db.refresh(floor_model)
    return floor


@router.delete("/{org_id}/deleteFloor/{floor_id}")
async def delete_floor(org_id: int, floor_id: int, db: Session = Depends(get_db)):
    org_floor_model = db.query(models.Floor).filter(models.Floor.org_id == org_id, models.Floor.id == floor_id).first()

    if org_floor_model is None:
        raise HTTPException(
            detail=f" The org id: {org_id} with given floor id : {floor_id} does not exists..!",
            status_code=404
        )
    else:
        db.query(models.Floor).filter(models.Floor.org_id == org_id, models.Floor.id == floor_id).delete()
    db.commit()
    return f" The floor with given ID {floor_id}, has been deleted successfully..!"


@router.get("/{org_id}/getSites")
async def get_sites(org_id: int, db: Session = Depends(get_db)):
    org_check = db.query(models.Floor).filter(models.Floor.org_id == org_id).first()
    if org_check is None:
        raise HTTPException(
            status_code=404,
            detail=f" The Org with given id :{org_id} does not exists..!"
        )
    get_site = db.query(models.Floor.Manage_Site_Id, models.Floor.Manage_Site_Name).distinct().all()

    return get_site


@router.post("/{org_id}/{floor_id}/createZoneRoom", response_model=schemas.ZoneRoomBase)
async def create_zone_room(org_id: int, floor_id: int, zone: ZoneRoomBase, db: Session = Depends(get_db)):
    zone_model = models.ZoneRoom()

    zone_model.Ext_Boundary_Points = zone.Ext_Boundary_Points
    zone_model.Ext_Floor_Id = zone.Ext_Floor_Id
    zone_model.Ext_Room_Id = zone.Ext_Room_Id
    zone_model.Ext_Room_Name = zone.Ext_Room_Name
    zone_model.Ext_Zone_Id = zone.Ext_Zone_Id
    zone_model.Ext_Zone_Name = zone.Ext_Zone_Name
    zone_model.Ext_Zone_Room_Name = zone.Ext_Zone_Room_Name
    zone_model.floor_id = floor_id
    zone_model.org_id = org_id

    db.add(zone_model)
    db.commit()
    db.refresh(zone_model)
    return zone


@router.delete("/{org_id}/{floor_id}/deleteZoneRoom/{zone_room_id}")
async def delete_zone_room(org_id: int, floor_id: int, zone_room_id=int, db: Session = Depends(get_db)):
    org_floor_zone = db.query(models.ZoneRoom).filter(models.ZoneRoom.org_id == org_id,
                                                      models.ZoneRoom.floor_id == floor_id,
                                                      models.ZoneRoom.id == zone_room_id).first()

    if org_floor_zone is None:
        raise HTTPException(
            detail=f" The org id: {org_id} with given floor id : {floor_id} does not exists..!",
            status_code=404
        )
    else:
        db.query(models.ZoneRoom).filter(models.ZoneRoom.org_id == org_id,
                                         models.ZoneRoom.floor_id == floor_id,
                                         models.ZoneRoom.id == zone_room_id).delete()
    db.commit()
    return f" The ZoneRoom {zone_room_id} with org id: {org_id} and floor id: {floor_id} has been deleted " \
           f"successfully..! "


@router.get("/{org_id}/{floor_id}/getZoneRooms")
async def get_zone_rooms(org_id: int, floor_id: int, db: Session = Depends(get_db)):
    org_floor_zone = db.query(models.ZoneRoom).filter(models.ZoneRoom.org_id == org_id,
                                                      models.ZoneRoom.floor_id == floor_id).all()

    if org_floor_zone is None:
        raise HTTPException(
            status_code=404,
            detail=f"The ZoneRoom with org id: {org_id} and  floor id : {floor_id} does not exists..!"
        )

    return org_floor_zone


@router.get("/{org_id}/{site_id}/getBuildings")
async def Read_Buildings(org_id: str, site_id: str, db: Session = Depends(get_db)):
    org_site_check = db.query(models.Floor).filter(models.Floor.org_id == org_id,
                                                   models.Floor.Manage_Site_Id == site_id).first()

    if org_site_check is None:
        raise HTTPException(
            status_code=404,
            detail=f" The Building with given org id : {org_id} and site_id {site_id} does not exists..!"
        )

    get_building = db.query(models.Floor.Manage_Building_Id,
                            models.Floor.Manage_Building_Name
                            ).filter(models.Floor.Manage_Site_Id == site_id).distinct().all()

    return get_building

