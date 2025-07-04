import logging
from typing import Any

from django.conf import settings
from django.contrib.auth import logout as django_logout
from django.db.utils import IntegrityError
from django.http import HttpRequest
from django.middleware import csrf
from django.shortcuts import redirect
from logs_helper.log_service import LogService
from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response
from tenant_account_v2.models import OrganizationMember as OrganizationMember
from tenant_account_v2.organization_member_service import OrganizationMemberService
from utils.cache_service import CacheService
from utils.local_context import StateStore
from utils.user_context import UserContext
from utils.user_session import UserSessionUtils

from account_v2.authentication_helper import AuthenticationHelper
from account_v2.authentication_plugin_registry import AuthenticationPluginRegistry
from account_v2.authentication_service import AuthenticationService
from account_v2.constants import (
    AuthorizationErrorCode,
    Common,
    Cookie,
    ErrorMessage,
    OrganizationMemberModel,
)
from account_v2.custom_exceptions import (
    DuplicateData,
    Forbidden,
    MethodNotImplemented,
    UserNotExistError,
)
from account_v2.dto import (
    MemberInvitation,
    OrganizationData,
    UserInfo,
    UserInviteResponse,
    UserRoleData,
)
from account_v2.exceptions import OrganizationNotExist
from account_v2.models import Organization, User
from account_v2.organization import OrganizationService
from account_v2.serializer import (
    GetOrganizationsResponseSerializer,
    OrganizationSerializer,
    SetOrganizationsResponseSerializer,
)
from account_v2.user import UserService

logger = logging.getLogger(__name__)


class AuthenticationController:
    """Authentication Controller This controller class manages user
    authentication processes.
    """

    def __init__(self) -> None:
        """This method initializes the controller by selecting the appropriate
        authentication plugin based on availability.
        """
        self.authentication_helper = AuthenticationHelper()
        if AuthenticationPluginRegistry.is_plugin_available():
            self.auth_service: AuthenticationService = (
                AuthenticationPluginRegistry.get_plugin()
            )
        else:
            self.auth_service = AuthenticationService()

    def user_login(
        self,
        request: Request,
    ) -> Any:
        return self.auth_service.user_login(request)

    def user_signup(self, request: Request) -> Any:
        return self.auth_service.user_signup(request)

    def authorization_callback(
        self, request: Request, backend: str = settings.DEFAULT_MODEL_BACKEND
    ) -> Any:
        """Handle authorization callback.

        This function processes the authorization callback from
        an external service.

        Args:
            request (Request): Request instance
            backend (str, optional): backend used to use login.
                Defaults: settings.DEFAULT_MODEL_BACKEND.

        Returns:
            Any: Redirect response
        """
        try:
            return self.auth_service.handle_authorization_callback(
                request=request, backend=backend
            )
        except Exception as ex:
            logger.error(f"Error while handling authorization callback: {ex}")
            return redirect("/error")

    def user_organizations(self, request: Request) -> Any:
        """List a user's organizations.

        Args:
            user (User): User instance
            z_code (str): _description_

        Returns:
            list[OrganizationData]: _description_
        """
        try:
            organizations = self.auth_service.user_organizations(request)
        except Exception as ex:
            #
            self.user_logout(request)

            response = Response(
                status=status.HTTP_412_PRECONDITION_FAILED,
            )
            if hasattr(ex, "code") and ex.code in {
                AuthorizationErrorCode.USF,
                AuthorizationErrorCode.USR,
                AuthorizationErrorCode.INE001,
                AuthorizationErrorCode.INE002,
                AuthorizationErrorCode.INS,
            }:  # type: ignore
                response.data = {"domain": ex.data.get("domain"), "code": ex.code}
                return response
            # Return in case even if missed unknown exception in
            # self.auth_service.user_organizations(request)
            return response

        user: User = request.user
        org_ids = {org.id for org in organizations}

        CacheService.set_user_organizations(user.user_id, list(org_ids))

        serialized_organizations = GetOrganizationsResponseSerializer(
            organizations, many=True
        ).data
        response = Response(
            status=status.HTTP_200_OK,
            data={
                "message": "success",
                "organizations": serialized_organizations,
            },
        )
        if Cookie.CSRFTOKEN not in request.COOKIES:
            csrf_token = csrf.get_token(request)
            response.set_cookie(Cookie.CSRFTOKEN, csrf_token)

        return response

    def _get_user_organization_ids(self, user_id: str) -> set[str]:
        """Get organization IDs for a user from cache or service."""
        organization_ids = CacheService.get_user_organizations(user_id)
        if not organization_ids:
            z_organizations: list[OrganizationData] = (
                self.auth_service.get_organizations_by_user_id(user_id)
            )
            organization_ids = {org.id for org in z_organizations}
        return organization_ids

    def _get_or_create_organization(self, organization_id: str) -> tuple[Organization, bool]:
        """Get existing organization or create new one."""
        organization = OrganizationService.get_organization_by_org_id(organization_id)
        if organization:
            return organization, False
            
        try:
            organization_data: OrganizationData = (
                self.auth_service.get_organization_by_org_id(organization_id)
            )
        except ValueError:
            raise OrganizationNotExist()
            
        try:
            organization = OrganizationService.create_organization(
                organization_data.name,
                organization_data.display_name,
                organization_data.id,
            )
            return organization, True
        except IntegrityError:
            raise DuplicateData(
                f"{ErrorMessage.ORGANIZATION_EXIST}, {ErrorMessage.DUPLICATE_API}"
            )

    def _handle_new_organization(self, organization: Organization, user: User) -> None:
        """Handle setup for newly created organization."""
        try:
            self.auth_service.frictionless_onboarding(
                organization=organization, user=user
            )
        except MethodNotImplemented:
            logger.info("frictionless_onboarding not implemented")

        self.authentication_helper.create_initial_platform_key(
            user=user, organization=organization
        )
        logger.info(f"New organization created with Id {organization.organization_id}")

    def _update_user_session(self, request: Request, user: User, 
                           organization_id: str, organization_member: OrganizationMember) -> None:
        """Update user session with new organization."""
        current_organization_id = UserSessionUtils.get_organization_id(request)
        if current_organization_id:
            OrganizationMemberService.remove_user_membership_in_organization_cache(
                user_id=user.user_id,
                organization_id=current_organization_id,
            )
        UserSessionUtils.set_organization_id(request, organization_id)
        UserSessionUtils.set_organization_member_role(request, organization_member)
        OrganizationMemberService.set_user_membership_in_organization_cache(
            user_id=user.user_id, organization_id=organization_id
        )

    def set_user_organization(self, request: Request, organization_id: str) -> Response:
        user: User = request.user
        organization_ids = self._get_user_organization_ids(user.user_id)
        
        if not (organization_id and organization_id in organization_ids):
            return Response(status=status.HTTP_403_FORBIDDEN)
            
        # Set organization in user context
        UserContext.set_organization_identifier(organization_id)
        
        # Get or create organization
        organization, new_organization = self._get_or_create_organization(organization_id)
        
        # Create tenant user
        organization_member = self.create_tenant_user(
            organization=organization, user=user
        )
        
        # Handle new organization setup
        if new_organization:
            self._handle_new_organization(organization, user)
        
        # Prepare response
        user_info: UserInfo | None = self.get_user_info(request)
        serialized_user_info = SetOrganizationsResponseSerializer(user_info).data
        organization_info = OrganizationSerializer(organization).data
        response: Response = Response(
            status=status.HTTP_200_OK,
            data={
                "is_new_org": new_organization,
                "user": serialized_user_info,
                "organization": organization_info,
                f"{Common.LOG_EVENTS_ID}": StateStore.get(Common.LOG_EVENTS_ID),
            },
        )
        
        # Update user session
        self._update_user_session(request, user, organization_id, organization_member)
        
        return response

    def get_user_info(self, request: Request) -> UserInfo | None:
        return self.auth_service.get_user_info(request)

    def is_admin_by_role(self, role: str) -> bool:
        """Check the role is act as admin in the context of authentication
        plugin.

        Args:
            role (str): role

        Returns:
            bool: _description_
        """
        return self.auth_service.is_admin_by_role(role=role)

    def get_organization_info(self, org_id: str) -> Organization | None:
        organization = OrganizationService.get_organization_by_org_id(org_id=org_id)
        return organization

    def make_organization_and_add_member(
        self,
        user_id: str,
        user_name: str,
        organization_name: str | None = None,
        display_name: str | None = None,
    ) -> OrganizationData | None:
        return self.auth_service.make_organization_and_add_member(
            user_id, user_name, organization_name, display_name
        )

    def make_user_organization_name(self) -> str:
        return self.auth_service.make_user_organization_name()

    def make_user_organization_display_name(self, user_name: str) -> str:
        return self.auth_service.make_user_organization_display_name(user_name)

    def user_logout(self, request: Request) -> Response:
        session_id: str = UserSessionUtils.get_session_id(request=request)
        LogService.remove_logs_on_logout(session_id=session_id)
        response = self.auth_service.user_logout(request=request)
        organization_id = UserSessionUtils.get_organization_id(request)
        user_id = UserSessionUtils.get_user_id(request)
        if organization_id:
            OrganizationMemberService.remove_user_membership_in_organization_cache(
                user_id=user_id, organization_id=organization_id
            )
        django_logout(request)
        return response

    def get_organization_members_by_org_id(
        self
    ) -> list[OrganizationMember]:
        members: list[OrganizationMember] = OrganizationMemberService.get_members()
        return members

    def get_organization_members_by_user(self, user: User) -> OrganizationMember:
        """Get organization member by user. This method will return
        organization member object for given user.

        Args:
            user (User): UserEntity

        Returns:
            OrganizationMember: OrganizationMemberEntity
        """
        member: OrganizationMember = OrganizationMemberService.get_user_by_id(id=user.id)
        return member

    def get_user_roles(self) -> list[UserRoleData]:
        return self.auth_service.get_roles()

    def get_user_invitations(self, organization_id: str) -> list[MemberInvitation]:
        return self.auth_service.get_invitations(organization_id=organization_id)

    def delete_user_invitation(self, organization_id: str, invitation_id: str) -> bool:
        return self.auth_service.delete_invitation(
            organization_id=organization_id, invitation_id=invitation_id
        )

    def reset_user_password(self, user: User) -> Response:
        return self.auth_service.reset_user_password(user)

    def invite_user(
        self,
        admin: User,
        org_id: str,
        user_list: list[dict[str, str | None]],
        request: HttpRequest,
    ) -> list[UserInviteResponse]:
        """Invites users to join an organization.

        Args:
            admin (User): Admin user initiating the invitation.
            org_id (str): ID of the organization to which users are invited.
            user_list (list[dict[str, Union[str, None]]]):
                List of user details for invitation.

        Returns:
            list[UserInviteResponse]: List of responses for each
                user invitation.
        """
        admin_user = OrganizationMemberService.get_user_by_id(id=admin.id)
        if not self.auth_service.is_organization_admin(admin_user):
            raise Forbidden()
        response = []
        for user_item in user_list:
            email = user_item.get("email")
            role = user_item.get("role")
            if email:
                user = OrganizationMemberService.get_user_by_email(email=email)
                user_response = {}
                user_response["email"] = email
                status = False
                message = "User is already part of current organization"
                # Check if user is already part of current organization
                if not user:
                    status = self.auth_service.invite_user(
                        admin_user, org_id, email, role=role, request=request
                    )
                    message = "User invitation successful."

                response.append(
                    UserInviteResponse(
                        email=email,
                        status="success" if status else "failed",
                        message=message,
                    )
                )
        return response

    def remove_users_from_organization(
        self, request: Request, organization_id: str, user_emails: list[str]
    ) -> bool:
        admin: User = request.user
        admin_user = OrganizationMemberService.get_user_by_id(id=admin.id)
        user_ids = OrganizationMemberService.get_members_by_user_email(
            user_emails=user_emails,
            values_list_fields=[
                OrganizationMemberModel.USER_ID,
                OrganizationMemberModel.ID,
            ],
        )
        user_ids_list: list[str] = []
        pk_list: list[str] = []
        for user in user_ids:
            user_ids_list.append(user[0])
            pk_list.append(user[1])
        if len(user_ids_list) > 0:
            is_removed = self.auth_service.remove_users_from_organization(
                admin=admin_user,
                organization_id=organization_id,
                user_ids=user_ids_list,
                request=request,
            )
        else:
            is_removed = False
        if is_removed:
            AuthenticationHelper.remove_users_from_organization_by_pks(pk_list)
            for user_id in user_ids_list:
                OrganizationMemberService.remove_user_membership_in_organization_cache(
                    user_id, organization_id
                )

        return is_removed

    def add_user_role(
        self, request: Request, org_id: str, email: str, role: str
    ) -> str | None:
        admin: User = request.user
        admin_user = OrganizationMemberService.get_user_by_id(id=admin.id)
        user = OrganizationMemberService.get_user_by_email(email=email)
        if user:
            current_roles = self.auth_service.add_organization_user_role(
                admin_user, org_id, user.user.user_id, [role], request
            )
            if current_roles:
                self.save_organization_user_role(
                    user_uid=user.user.id, role=current_roles[0]
                )
            return current_roles[0]
        else:
            return None

    def remove_user_role(
        self, request: Request, org_id: str, email: str, role: str
    ) -> str | None:
        admin: User = request.user
        admin_user = OrganizationMemberService.get_user_by_id(id=admin.id)
        organization_member = OrganizationMemberService.get_user_by_email(email=email)
        if organization_member:
            current_roles = self.auth_service.remove_organization_user_role(
                admin_user, org_id, organization_member.user.user_id, [role], request
            )
            if current_roles:
                self.save_organization_user_role(
                    user_uid=organization_member.user.id,
                    role=current_roles[0],
                )
            return current_roles[0]
        else:
            return None

    def save_organization_user_role(self, user_uid: str, role: str) -> None:
        organization_user = OrganizationMemberService.get_user_by_id(id=user_uid)
        if organization_user:
            # consider single role
            organization_user.role = role
            organization_user.save()

    def create_tenant_user(
        self, organization: Organization, user: User
    ) -> OrganizationMember:
        existing_tenant_user = OrganizationMemberService.get_user_by_id(id=user.id)

        # even if existing tenat user updat him with latest role from auth0 org
        if existing_tenant_user:
            user_roles = self.auth_service.get_organization_role_of_user(
                user_id=existing_tenant_user.user.user_id,
                organization_id=organization.organization_id,
            )
            existing_tenant_user.role = user_roles[0]
            existing_tenant_user.save()
            return existing_tenant_user

        account_user = self.get_or_create_user(user=user)
        if not account_user:
            raise UserNotExistError()

        logger.info(f"Creating account for {user.email}")
        user_roles = self.auth_service.get_organization_role_of_user(
            user_id=account_user.user_id,
            organization_id=organization.organization_id,
        )
        user_role = user_roles[0]
        try:
            tenant_user: OrganizationMember = OrganizationMember(
                user=user,
                role=user_role,
                is_login_onboarding_msg=False,
                is_prompt_studio_onboarding_msg=False,
            )
            tenant_user.save()
            logger.info(
                f"{tenant_user.user.email} added in to the organization "
                f"{organization.organization_id}"
            )
            return tenant_user
        except IntegrityError:
            logger.warning(f"Account already exists for {user.email}")

    def get_or_create_user(self, user: User) -> User | OrganizationMember | None:
        user_service = UserService()
        if user.id:
            account_user: User | None = user_service.get_user_by_id(user.id)
            if account_user:
                return account_user
            elif user.email:
                account_user = user_service.get_user_by_email(email=user.email)
                if account_user:
                    return account_user
                if user.user_id:
                    user.save()
                    return user
        elif user.email and user.user_id:
            account_user = user_service.create_user(
                email=user.email, user_id=user.user_id
            )
            return account_user
        return None
