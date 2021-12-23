--
-- Username: trinity
-- Password: trinity
-- Salt: 50f82985ee2bf8ffc06fa2bc3b39068c3fbebf16d0723c0bb5532d20fc45af51
-- Verifier: 9563a3b7f23f8b3e3367aba1b8034e9a0c615dd568ff3b956f961fd517fa2810
--
-- Set account password:
REPLACE INTO account (salt, verifier, username) VALUES (X'50f82985ee2bf8ffc06fa2bc3b39068c3fbebf16d0723c0bb5532d20fc45af51', X'9563a3b7f23f8b3e3367aba1b8034e9a0c615dd568ff3b956f961fd517fa2810', 'TRINITY');
-- Enable account GM access:
REPLACE INTO account_access (AccountID, SecurityLevel) VALUES ((SELECT id FROM account WHERE username = 'TRINITY'), 3);
--
