;; Social Media Engagement Rewards Contract
;; This contract manages the verification and reward distribution for social media engagement

;; Token trait definition
(use-trait token-trait .token-trait.token-trait)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-engagement (err u103))
(define-constant err-already-rewarded (err u104))
(define-constant err-invalid-platform (err u105))
(define-constant err-low-verification-score (err u106))

;; Data Maps

;; Map to associate social media accounts with Stacks addresses
;; platform-id: string combining platform name and account ID (e.g. "twitter:username")
(define-map account-registry
  { platform-id: (string-ascii 50) }
  { stacks-address: principal, platform: (string-ascii 20) }
)

;; Map to track engagement events that have been rewarded
(define-map engagement-events
  { event-id: (string-ascii 100) }
  { 
    rewarded: bool,
    reward-amount: uint,
    timestamp: uint
  }
)

;; Map to store reward rates for different engagement types
(define-map reward-rates
  { platform: (string-ascii 20), engagement-type: (string-ascii 20) }
  { base-reward: uint }
)

;; Map to track user total rewards
(define-map user-rewards
  { user: principal }
  { total-earned: uint }
)

;; Data Variables
(define-data-var min-verification-score uint u70) ;; Minimum score (0-100) required to validate engagement
(define-data-var reward-multiplier uint u100) ;; Base multiplier for rewards (100 = 1x)
(define-data-var platform-list (list 10 (string-ascii 20)) (list "twitter" "instagram" "tiktok" "facebook" "linkedin"))
(define-data-var token-contract principal contract-owner) ;; Address of the token contract

;; Read-only Functions

;; Get the current token contract
(define-read-only (get-token-contract)
  (var-get token-contract)
)

;; Check if a user is registered for a platform
(define-read-only (is-registered (platform-id (string-ascii 50)))
  (is-some (map-get? account-registry { platform-id: platform-id }))
)

;; Get the reward rate for a specific engagement type on a platform
(define-read-only (get-reward-rate (platform (string-ascii 20)) (engagement-type (string-ascii 20)))
  (default-to { base-reward: u0 }
    (map-get? reward-rates { platform: platform, engagement-type: engagement-type })
  )
)

;; Get the total rewards earned by a user
(define-read-only (get-user-total-rewards (user principal))
  (default-to { total-earned: u0 }
    (map-get? user-rewards { user: user })
  )
)

;; Check if an engagement event has already been rewarded
(define-read-only (is-engagement-rewarded (event-id (string-ascii 100)))
  (match (map-get? engagement-events { event-id: event-id })
    event-data (get rewarded event-data)
    false
  )
)

;; Check if a platform is supported
(define-read-only (is-platform-supported (platform (string-ascii 20)))
  (is-some (index-of (var-get platform-list) platform))
)

;; Public Functions

;; Register a social media account to a Stacks address
(define-public (register-account (platform-id (string-ascii 50)) (platform (string-ascii 20)))
  (begin
    ;; Check if already registered
    (asserts! (not (is-registered platform-id)) err-already-registered)
    
    ;; Check if platform is supported
    (asserts! (is-platform-supported platform) err-invalid-platform)
    
    ;; Register the account
    (map-set account-registry
      { platform-id: platform-id }
      { stacks-address: tx-sender, platform: platform }
    )
    
    (ok true)
  )
)

;; Claim rewards for a verified engagement event
(define-public (claim-engagement-reward 
              (event-id (string-ascii 100))
              (platform (string-ascii 20))
              (engagement-type (string-ascii 20))
              (platform-id (string-ascii 50))
              (verification-score uint)
              (token-contract-addr <token-trait>))
  (let (
    (reward-data (get-reward-rate platform engagement-type))
    (base-reward (get base-reward reward-data))
    (user-data (map-get? account-registry { platform-id: platform-id }))
  )
    ;; Check if the platform is supported
    (asserts! (is-platform-supported platform) err-invalid-platform)
    
    ;; Check if the account is registered
    (asserts! (is-some user-data) err-not-registered)
    
    ;; Check if the event has already been rewarded
    (asserts! (not (is-engagement-rewarded event-id)) err-already-rewarded)
    
    ;; Check if verification score meets minimum requirement
    (asserts! (>= verification-score (var-get min-verification-score)) err-low-verification-score)
    
    ;; Calculate the actual reward
    (let (
      (reward-amount (calculate-reward base-reward verification-score))
      (user-address (get stacks-address (unwrap-panic user-data)))
    )
      ;; Record the engagement event as rewarded
      (map-set engagement-events
        { event-id: event-id }
        { 
          rewarded: true,
          reward-amount: reward-amount,
          timestamp: block-height
        }
      )
      
      ;; Update user's total rewards
      (update-user-rewards user-address reward-amount)
      
      ;; Mint tokens to the user using the token contract
      (as-contract 
        (contract-call? token-contract-addr mint reward-amount user-address)
      )
    )
  )
)

;; Helper function to calculate the reward amount based on verification score
(define-private (calculate-reward (base-reward uint) (verification-score uint))
  (let (
    (score-factor (/ (* verification-score u100) u100))
    (multiplier (var-get reward-multiplier))
  )
    (/ (* base-reward score-factor multiplier) u10000)
  )
)

;; Helper function to update a user's total rewards
(define-private (update-user-rewards (user principal) (amount uint))
  (let (
    (current-total (get total-earned (default-to { total-earned: u0 } (map-get? user-rewards { user: user }))))
  )
    (map-set user-rewards
      { user: user }
      { total-earned: (+ current-total amount) }
    )
  )
)

;; Admin Functions

;; Set the token contract address
(define-public (set-token-contract (new-token-contract principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set token-contract new-token-contract)
    (ok true)
  )
)

;; Set the reward rate for a specific engagement type on a platform
(define-public (set-reward-rate (platform (string-ascii 20)) (engagement-type (string-ascii 20)) (base-reward uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-platform-supported platform) err-invalid-platform)
    
    (map-set reward-rates
      { platform: platform, engagement-type: engagement-type }
      { base-reward: base-reward }
    )
    
    (ok true)
  )
)

;; Set the minimum verification score required
(define-public (set-min-verification-score (new-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-score u100) (err u107)) ;; Score must be between 0-100
    
    (var-set min-verification-score new-score)
    (ok true)
  )
)

;; Set the reward multiplier
(define-public (set-reward-multiplier (new-multiplier uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (var-set reward-multiplier new-multiplier)
    (ok true)
  )
)

;; Add a new supported platform
(define-public (add-platform (platform (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (is-platform-supported platform)) (err u108)) ;; Platform already exists
    
    (var-set platform-list (append (var-get platform-list) platform))
    (ok true)
  )
)

;; Initialize default reward rates
(begin
  ;; Set default reward rates for common engagement types
  (map-set reward-rates { platform: "twitter", engagement-type: "like" } { base-reward: u10 })
  (map-set reward-rates { platform: "twitter", engagement-type: "retweet" } { base-reward: u30 })
  (map-set reward-rates { platform: "twitter", engagement-type: "comment" } { base-reward: u50 })
  (map-set reward-rates { platform: "twitter", engagement-type: "post" } { base-reward: u100 })
  
  (map-set reward-rates { platform: "instagram", engagement-type: "like" } { base-reward: u10 })
  (map-set reward-rates { platform: "instagram", engagement-type: "comment" } { base-reward: u40 })
  (map-set reward-rates { platform: "instagram", engagement-type: "post" } { base-reward: u100 })
  
  true
)
