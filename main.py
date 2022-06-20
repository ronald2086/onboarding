import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import models
from app.database import engine
from routers import org, user, dcsession, user_tags

# if you are using alembic migrations then comment bellow command
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
        title="Org",
        docs_url="/onboarding/v1/")

origins = [
    "http://localhost:8079",
    "http://localhost:8079/build/web/#/"
    "http://localhost",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(org.router)
app.include_router(user.router)
app.include_router(user_tags.router)
app.include_router(dcsession.router)


if __name__ == '__main__':
    uvicorn.run(app, port=8000, host="localhost")
