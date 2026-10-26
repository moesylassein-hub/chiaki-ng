# Incomplete console login

The control handshake recognizes login success (0) and an incorrect PIN (1).
Other status values have undocumented meanings. Previously, after the normal
startup wait, a missing session ID could cause the client to create a fallback
ID even after an unhandled login status. Streaming was then attempted without
evidence that login had completed.

The session now remembers the last valid login status under its state mutex.
After the existing startup/PIN wait, an unhandled status with no real session
ID ends the attempt with a specific error and the status value. It does not
enter data-channel negotiation or the session-ID fallback. A subsequent login
success or a real session ID permits normal operation. No status message and
successful-login cases retain the existing compatibility fallback. Normal PIN
entry/retry behavior is retained. This error does not trigger automatic retries.

The GUI suggests checking the active console user and retrying with a directly
connected PS5 controller turned off. This is troubleshooting guidance, not a
claim that any particular status means "controller conflict". The experimental
direct-controller option changes the streaming input announcement; it does not
change console authentication or guarantee simultaneous same-account use.

Tests compile the production login handler and fallback gate with small protocol
stubs, covering empty messages, all unhandled status bytes, real session IDs,
late success, and incorrect-PIN handling. Live PS5 tests remain necessary to
confirm account/controller behavior. This change fixes misleading connection
progress; it does not force the console to accept a refused login.
