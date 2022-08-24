# Socket Command Center

This is the command center for Socket registry on all chains, the owner on the Socket contract would be directed to this contract

It allows us to seperate out the roles for Owner and Pauser, such that Pauser could be given out more freely while owner could be just the team.
Pauser will only have the ability to pause the system while the owner will have the ability to add new routes.

Pausers can be assigned the `PAUSER` role and once they have that they can either call
- `pause` can only be called by the EOA which has be assigned the PAUSER role

There is only one `owner` to the system:
- can make authorised calls to socket via `makeAuthorisedCall` to add new routes etc
- can assign and revoke the `PAUSER` roles