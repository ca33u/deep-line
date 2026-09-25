# Deep Line Privacy Policy

Effective for the KiezelPay-enabled update prepared September 25, 2026.
Earlier free versions do not include the payment integration described below.

## Gameplay and local storage

Campaign progress, stars and best scores are stored locally on the Garmin device.
Deep Line does not use health, location, activity, contacts, advertising or analytics
services. The first three levels can be played without a payment or network
connection. Removing the app or clearing its storage removes local progress and
may require restoration of a purchase.

## Optional full-campaign purchase

Deep Line uses KiezelPay to sell and restore access to the full campaign. The
Connect IQ Communications permission allows the game to contact KiezelPay through
your paired phone. When you start a purchase or restore, the library sends the
KiezelPay product ID, an account/device token, the Garmin device part number,
library version, request timestamp and purchase-mode flags to
https://api.kiezelpay.com/api/v2/status. The library uses the device identifier
when available, or a locally generated token. It stores the license state,
purchase code, token and license-check timestamps on the watch.

After a purchase flow has been started, the library can check its status on
subsequent launches and retry while the app runs. Licensed access is cached for
offline play; a later successful server response can update or revoke that
license. Gameplay progress and scores are not sent to KiezelPay.

Checkout occurs on KiezelPay's website. Deep Line does not receive payment-card
details. Information entered at checkout is handled by KiezelPay and its payment
providers under their terms and privacy policies. Purchase restoration may use
the email address supplied at checkout: https://kzl.io/unlock.

## Prior free players

On first launch of this update, players with an existing saved score or unlocked
campaign progress retain full access locally. Those players do not need a
KiezelPay license. That local entitlement may be lost if app storage is deleted.

## Support

Email: deepline@addicted.sh
Technical issues: https://github.com/ca33u/deep-line/issues
Please do not post payment details, purchase codes or personal data publicly.
