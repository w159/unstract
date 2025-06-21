module.exports = {
	extends: ["react-app", "react-app/jest"],
	rules: {
		"valid-jsdoc": "off",
		"react-hooks/rules-of-hooks": "error",
		"react-hooks/exhaustive-deps": "warn",
	},
};
