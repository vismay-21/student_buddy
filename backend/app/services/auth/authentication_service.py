import jwt
from jwt import PyJWKClient
import uuid
from fastapi import HTTPException, status
from pydantic import BaseModel
from app.core.config import settings

_jwks_client = None

def get_jwks_client() -> PyJWKClient:
    global _jwks_client
    if _jwks_client is None:
        if not settings.SUPABASE_URL:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="SUPABASE_URL configuration is missing. Cannot fetch JWKS."
            )
        jwks_url = f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json"
        _jwks_client = PyJWKClient(jwks_url, cache_jwk_set=True, lifespan=360)
    return _jwks_client


class CurrentUser(BaseModel):
    id: uuid.UUID
    email: str


class AuthenticationService:
    @staticmethod
    def verify_token(token: str) -> CurrentUser:
        try:
            header = jwt.get_unverified_header(token)
            alg = header.get("alg", "HS256")
            
            if alg == "HS256":
                # Decode the token using local JWT_SECRET
                payload = jwt.decode(
                    token,
                    settings.JWT_SECRET,
                    algorithms=["HS256"],
                    options={"verify_aud": False}  # Supabase aud is 'authenticated', disable to be robust
                )
            else:
                # Use JWKS client for asymmetric algorithms (like ES256, RS256)
                client = get_jwks_client()
                signing_key = client.get_signing_key_from_jwt(token)
                payload = jwt.decode(
                    token,
                    signing_key.key,
                    algorithms=[alg],
                    options={"verify_aud": False}
                )
            
            user_id_str = payload.get("sub")
            email = payload.get("email")
            
            if not user_id_str:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token: missing subject claim"
                )
                
            try:
                user_id = uuid.UUID(user_id_str)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token: subject claim is not a valid UUID"
                )
                
            return CurrentUser(id=user_id, email=email or "")
            
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired"
            )
        except jwt.InvalidTokenError as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid token: {str(e)}"
            )
