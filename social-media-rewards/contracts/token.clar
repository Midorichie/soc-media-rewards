;; SIP-010 Fungible Token for Social Media Engagement Rewards
;; This contract implements a fungible token following the SIP-010 standard

(define-fungible-token engagement-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-not-authorized (err u102))

;; Data variables
(define-data-var token-name (string-ascii 32) "EngagementToken")
(define-data-var token-symbol (string-ascii 10) "ENGAGE")
(define-data-var token-decimals uint u6)
(define-data-var token-uri (optional (string-utf8 256)) none)

;; SIP-010 Interface Functions

;; Get the token balance for a specified account
(define-read-only (get-balance (account principal))
  (ok (ft-get-balance engagement-token account))
)

;; Get the token's metadata
(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

;; Get the token's name
(define-read-only (get-name)
  (ok (var-get token-name))
)

;; Get the token's symbol
(define-read-only (get-symbol)
  (ok (var-get token-symbol))
)

;; Get the token's decimals
(define-read-only (get-decimals)
  (ok (var-get token-decimals))
)

;; Get the token's total supply
(define-read-only (get-total-supply)
  (ok (ft-get-supply engagement-token))
)

;; Transfer tokens between accounts - only succeeds if called by the token owner
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    ;; Ensure the caller is the token owner
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    
    ;; Perform the transfer
    (try! (ft-transfer? engagement-token amount sender recipient))
    
    ;; If a memo is provided and we're not in clarity 1, handle it
    (match memo
      memo-data (print memo-data)
      none true
    )
    
    (ok true)
  )
)

;; Mint new tokens - only callable by the engagement-rewards contract
(define-public (mint (amount uint) (recipient principal))
  (begin
    ;; Only the engagement-rewards contract can mint tokens
    (asserts! (is-eq contract-caller 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.engagement-rewards) err-not-authorized)
    
    ;; Mint tokens to the recipient
    (ft-mint? engagement-token amount recipient)
  )
)

;; Admin Functions

;; Update the token URI - only callable by contract owner
(define-public (set-token-uri (new-uri (optional (string-utf8 256))))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set token-uri new-uri)
    (ok true)
  )
)

;; Initialize the contract - set up initial token state
(begin
  ;; No initial mint - tokens will only be created through engagement rewards
  true
)
