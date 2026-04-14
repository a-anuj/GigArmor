"""
HustleHalt — FastAPI Dependencies
Reusable `Depends(...)` callables shared across routers.
"""
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import decode_access_token, oauth2_scheme
from app.database import get_db
from app.models.worker import Worker


def get_current_worker(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Worker:
    """
    Dependency that extracts and verifies the JWT from the ``Authorization``
    header, then loads the corresponding Worker from the database.

    Raises HTTP 401 if the token is missing, invalid, or the worker doesn't exist.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    worker_id = decode_access_token(token)
    if worker_id is None:
        raise credentials_exception

    worker = db.query(Worker).filter(Worker.id == int(worker_id)).first()
    if worker is None:
        raise credentials_exception

    return worker
