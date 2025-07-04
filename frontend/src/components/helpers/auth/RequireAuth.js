import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useEffect } from 'react';

import {
  getOrgNameFromPathname,
  homePagePath,
  onboardCompleted,
} from '../../../helpers/GetStaticData';
import { useSessionStore } from '../../../store/session-store';
import usePostHogEvents from '../../../hooks/usePostHogEvents';

let ProductFruitsManager;
try {
  ProductFruitsManager =
    require('../../../plugins/product-fruits/ProductFruitsManager').ProductFruitsManager;
} catch {
  // The component will remain null of it is not available
}
let selectedProductStore;
let isLlmWhisperer;
let isVerticals;
try {
  selectedProductStore = require('../../../plugins/store/select-product-store.js');
} catch {
  // do nothing
}

const RequireAuth = () => {
  const { sessionDetails } = useSessionStore();
  const { setPostHogIdentity } = usePostHogEvents();
  const location = useLocation();
  const isLoggedIn = sessionDetails?.isLoggedIn;
  const orgName = sessionDetails?.orgName;
  const pathname = location?.pathname;
  const adapters = sessionDetails?.adapters;
  try {
    isLlmWhisperer =
      selectedProductStore.useSelectedProductStore(
        (state) => state?.selectedProduct,
      ) === 'llm-whisperer';
  } catch (error) {
    // Do nothing
  }
  try {
    isVerticals =
      selectedProductStore.useSelectedProductStore(
        (state) => state?.selectedProduct,
      ) === 'verticals';
  } catch (error) {
    // Do nothing
  }

  const currOrgName = getOrgNameFromPathname(
    pathname,
    isLlmWhisperer || isVerticals,
  );
  useEffect(() => {
    if (!sessionDetails?.isLoggedIn) {
      return;
    }

    setPostHogIdentity();
  }, [sessionDetails, setPostHogIdentity]);

  let navigateTo = `/${orgName}/onboard`;
  if (isLlmWhisperer) {
    navigateTo = `/llm-whisperer/${orgName}/playground`;
  } else if (isVerticals) {
    navigateTo = `/verticals/`;
  } else if (onboardCompleted(adapters)) {
    navigateTo = `/${orgName}/${homePagePath}`;
  }
  if (
    sessionDetails.role === 'unstract_reviewer' ||
    sessionDetails.role === 'unstract_supervisor'
  ) {
    navigateTo = `/${orgName}/review`;
  }

  if (!isLoggedIn) {
    return <Navigate to="/landing" state={{ from: location }} replace />;
  }

  if (currOrgName !== orgName) {
    return <Navigate to={navigateTo} />;
  }

  return (
    <>
      {ProductFruitsManager && <ProductFruitsManager />}
      <Outlet />
    </>
  );
};

export { RequireAuth };
