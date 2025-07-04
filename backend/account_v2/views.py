import logging
from typing import Any

from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.request import Request
from rest_framework.response import Response
from utils.user_session import UserSessionUtils

from account_v2.authentication_controller import AuthenticationController
from account_v2.dto import (
    OrganizationSignupRequestBody,
    OrganizationSignupResponse,
    UserSessionInfo,
)
from account_v2.models import Organization
from account_v2.organization import OrganizationService
from account_v2.serializer import (
    OrganizationSignupResponseSerializer,
    OrganizationSignupSerializer,
    UserSessionResponseSerializer,
)

Logger = logging.getLogger(__name__)


@api_view(["POST"])
def create_organization(request: Request) -> Response:
    serializer = OrganizationSignupSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    try:
        request_body: OrganizationSignupRequestBody = make_signup_request_params(serializer)

        organization: Organization = OrganizationService.create_organization(
            request_body.name,
            request_body.display_name,
            request_body.organization_id,
        )
        response = make_signup_response(organization)
        return Response(
            status=status.HTTP_201_CREATED,
            data={"message": "success", "tenant": response},
        )
    except Exception as error:
        Logger.error(error)
        return Response(
            status=status.HTTP_500_INTERNAL_SERVER_ERROR, data="Unknown Error"
        )


@api_view(["GET"])
def callback(request: Request) -> Response:
    auth_controller = AuthenticationController()
    return auth_controller.authorization_callback(request)


@api_view(["GET", "POST"])
def login(request: Request) -> Response:
    auth_controller = AuthenticationController()
    return auth_controller.user_login(request)


@api_view(["GET"])
def signup(request: Request) -> Response:
    auth_controller = AuthenticationController()
    return auth_controller.user_signup(request)


@api_view(["GET"])
def logout(request: Request) -> Response:
    auth_controller = AuthenticationController()
    return auth_controller.user_logout(request)


@api_view(["GET"])
def get_organizations(request: Request) -> Response:
    """get_organizations.

    Retrieve the list of organizations to which the user belongs.

    Args:
        request (HttpRequest): _description_

    Returns:
        Response: A list of organizations with associated information.
    """
    auth_controller = AuthenticationController()
    return auth_controller.user_organizations(request)


@api_view(["POST"])
def set_organization(request: Request, id: str) -> Response:
    """set_organization.

    Set the current organization to use.

    Args:
        request (HttpRequest): _description_
        id (String): organization Id

    Returns:
        Response: Contains the User and Current organization details.
    """
    auth_controller = AuthenticationController()
    return auth_controller.set_user_organization(request, id)


@api_view(["GET"])
def get_session_data(request: Request) -> Response:
    """get_session_data.

    Retrieve the current session data.

    Args:
        request (HttpRequest): _description_

    Returns:
        Response: Contains the User and Current organization details.
    """
    response = make_session_response(request)

    return Response(
        status=status.HTTP_201_CREATED,
        data=response,
    )


def make_session_response(
    request: Request,
) -> Any:
    """make_session_response.

    Make the current session data.

    Args:
        request (HttpRequest): _description_

    Returns:
        User and Current organization details.
    """
    auth_controller = AuthenticationController()
    token_data = UserSessionUtils.get_token_data(request)
    provider = "" if token_data is None else token_data.get("provider", "")
    return UserSessionResponseSerializer(
        UserSessionInfo(
            id=request.user.id,
            user_id=request.user.user_id,
            email=request.user.email,
            user=auth_controller.get_user_info(request),
            organization_id=UserSessionUtils.get_organization_id(request),
            role=UserSessionUtils.get_organization_member_role(request),
            provider=provider,
        )
    ).data


def make_signup_request_params(
    serializer: OrganizationSignupSerializer,
) -> OrganizationSignupRequestBody:
    return OrganizationSignupRequestBody(
        serializer.validated_data["name"],
        serializer.validated_data["display_name"],
        serializer.validated_data["organization_id"],
    )


def make_signup_response(
    organization: Organization,
) -> Any:
    return OrganizationSignupResponseSerializer(
        OrganizationSignupResponse(
            organization.name,
            organization.display_name,
            organization.organization_id,
            organization.created_at,
        )
    ).data
