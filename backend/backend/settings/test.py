# Import all settings from base
# Note: Wildcard import is intentional here as this is a Django settings module
# that needs to inherit all settings from the base configuration
from backend.settings.base import *  # noqa: F401, F403

DEBUG = True
