;; token-trait.clar
(define-trait token-trait
  (
    ;; Mint new tokens
    (mint (uint principal) (response bool uint))
    
    ;; Transfer tokens between accounts
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    
    ;; Get token balance
    (get-balance (principal) (response uint uint))
    
    ;; Get total supply
    (get-total-supply () (response uint uint))
  )
)
