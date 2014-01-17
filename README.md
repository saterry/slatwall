Slatwall Installation Notes
1/17/2014

Execute the following sql in the Slatwall database.

insert swintegration (integrationID,
integrationPackage, integrationName, installedFlag, authenticationReadyFlag, authenticationActiveFlag, customReadyFlag, customActiveFlag, fw1ReadyFlag, fw1ActiveFlag, paymentReadyFlag, paymentActiveFlag, shippingReadyFlag, shippingActiveFlag, createdDateTime, modifiedDateTime, createdByAccountID, modifiedByAccountID)
values (REPLACE(UUID(),'-',''),
'securesubmit', 'SecureSubmit', 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, now(), now(), NULL, NULL)


