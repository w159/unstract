import PropTypes from "prop-types";

// Stub implementation for RequirePlatformAdmin component
const RequirePlatformAdmin = ({ children }) => {
  return children || null;
};

RequirePlatformAdmin.propTypes = {
  children: PropTypes.node,
};

export default RequirePlatformAdmin;
