;; Student Skill Endorsement Contract
;; Peer-to-peer skill verification and endorsement system

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-self-endorse (err u101))
(define-constant err-already-endorsed (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-level (err u104))
(define-constant err-skill-limit (err u105))
(define-constant err-already-exists (err u106))
(define-constant max-skills-per-user u50)

;; Data Variables
(define-data-var skill-nonce uint u0)
(define-data-var total-endorsements uint u0)
(define-data-var platform-active bool true)

;; Data Maps
(define-map student-skills
  { student: principal, skill-id: uint }
  {
    skill-name: (string-ascii 100),
    proficiency-level: (string-ascii 20),
    added-at: uint,
    verified: bool,
    category: (string-ascii 50)
  }
)

(define-map endorsements
  { student: principal, skill-id: uint, endorser: principal }
  {
    endorsed-at: uint,
    comment: (string-ascii 200),
    rating: uint
  }
)

(define-map skill-endorsement-count
  { student: principal, skill-id: uint }
  uint
)

(define-map user-skills-count principal uint)

(define-map skill-categories
  (string-ascii 50)
  {
    active: bool,
    skill-count: uint
  }
)

(define-map user-reputation principal uint)

(define-map endorser-stats principal 
  {
    total-endorsements-given: uint,
    reputation-score: uint
  }
)

;; Read-only functions
;; #[allow(unchecked_data)]
(define-read-only (get-student-skill (student principal) (skill-id uint))
  (map-get? student-skills { student: student, skill-id: skill-id })
)

;; #[allow(unchecked_data)]
(define-read-only (get-endorsement (student principal) (skill-id uint) (endorser principal))
  (map-get? endorsements { student: student, skill-id: skill-id, endorser: endorser })
)

;; #[allow(unchecked_data)]
(define-read-only (get-endorsement-count (student principal) (skill-id uint))
  (default-to u0 (map-get? skill-endorsement-count { student: student, skill-id: skill-id }))
)

;; #[allow(unchecked_data)]
(define-read-only (get-user-skills-count (user principal))
  (default-to u0 (map-get? user-skills-count user))
)

(define-read-only (get-skill-nonce)
  (var-get skill-nonce)
)

;; #[allow(unchecked_data)]
(define-read-only (get-user-reputation (user principal))
  (default-to u0 (map-get? user-reputation user))
)

;; #[allow(unchecked_data)]
(define-read-only (get-endorser-stats (endorser principal))
  (default-to { total-endorsements-given: u0, reputation-score: u0 } 
    (map-get? endorser-stats endorser))
)

;; #[allow(unchecked_data)]
(define-read-only (get-category-info (category (string-ascii 50)))
  (map-get? skill-categories category)
)

(define-read-only (get-total-endorsements)
  (var-get total-endorsements)
)

(define-read-only (is-platform-active)
  (var-get platform-active)
)

;; #[allow(unchecked_data)]
(define-read-only (is-skill-verified (student principal) (skill-id uint))
  (match (get-student-skill student skill-id)
    skill (get verified skill)
    false
  )
)

;; #[allow(unchecked_data)]
(define-read-only (get-average-rating (student principal) (skill-id uint))
  (let
    (
      (count (get-endorsement-count student skill-id))
    )
    (if (> count u0)
      (ok count)
      err-not-found
    )
  )
)

;; Public functions
;; #[allow(unchecked_data)]
(define-public (add-skill (skill-name (string-ascii 100)) (proficiency-level (string-ascii 20)))
  (let
    (
      (skill-id (var-get skill-nonce))
      (student tx-sender)
      (current-skills (get-user-skills-count student))
    )
    (asserts! (< current-skills max-skills-per-user) err-skill-limit)
    (map-set student-skills 
      { student: student, skill-id: skill-id }
      {
        skill-name: skill-name,
        proficiency-level: proficiency-level,
        added-at: stacks-block-height,
        verified: false,
        category: "general"
      }
    )
    (map-set user-skills-count student (+ current-skills u1))
    (var-set skill-nonce (+ skill-id u1))
    (ok skill-id)
  )
)

;; #[allow(unchecked_data)]
(define-public (add-skill-with-category (skill-name (string-ascii 100)) (proficiency-level (string-ascii 20)) (category (string-ascii 50)))
  (let
    (
      (skill-id (var-get skill-nonce))
      (student tx-sender)
      (current-skills (get-user-skills-count student))
    )
    (asserts! (< current-skills max-skills-per-user) err-skill-limit)
    (map-set student-skills 
      { student: student, skill-id: skill-id }
      {
        skill-name: skill-name,
        proficiency-level: proficiency-level,
        added-at: stacks-block-height,
        verified: false,
        category: category
      }
    )
    (map-set user-skills-count student (+ current-skills u1))
    (var-set skill-nonce (+ skill-id u1))
    (update-category-count category)
    (ok skill-id)
  )
)

;; #[allow(unchecked_data)]
(define-public (endorse-skill (student principal) (skill-id uint) (comment (string-ascii 200)))
  (let
    (
      (endorser tx-sender)
      (skill (unwrap! (map-get? student-skills { student: student, skill-id: skill-id }) err-not-found))
      (current-count (get-endorsement-count student skill-id))
    )
    (asserts! (var-get platform-active) err-unauthorized)
    (asserts! (not (is-eq endorser student)) err-self-endorse)
    (asserts! (is-none (map-get? endorsements { student: student, skill-id: skill-id, endorser: endorser })) err-already-endorsed)
    (map-set endorsements 
      { student: student, skill-id: skill-id, endorser: endorser }
      {
        endorsed-at: stacks-block-height,
        comment: comment,
        rating: u5
      }
    )
    (map-set skill-endorsement-count
      { student: student, skill-id: skill-id }
      (+ current-count u1)
    )
    (var-set total-endorsements (+ (var-get total-endorsements) u1))
    (update-endorser-stats endorser)
    (update-user-reputation student)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (endorse-skill-with-rating (student principal) (skill-id uint) (comment (string-ascii 200)) (rating uint))
  (let
    (
      (endorser tx-sender)
      (skill (unwrap! (map-get? student-skills { student: student, skill-id: skill-id }) err-not-found))
      (current-count (get-endorsement-count student skill-id))
    )
    (asserts! (var-get platform-active) err-unauthorized)
    (asserts! (not (is-eq endorser student)) err-self-endorse)
    (asserts! (is-none (map-get? endorsements { student: student, skill-id: skill-id, endorser: endorser })) err-already-endorsed)
    (asserts! (and (>= rating u1) (<= rating u10)) err-invalid-level)
    (map-set endorsements 
      { student: student, skill-id: skill-id, endorser: endorser }
      {
        endorsed-at: stacks-block-height,
        comment: comment,
        rating: rating
      }
    )
    (map-set skill-endorsement-count
      { student: student, skill-id: skill-id }
      (+ current-count u1)
    )
    (var-set total-endorsements (+ (var-get total-endorsements) u1))
    (update-endorser-stats endorser)
    (update-user-reputation student)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (update-proficiency (skill-id uint) (new-level (string-ascii 20)))
  (let
    (
      (student tx-sender)
      (skill (unwrap! (map-get? student-skills { student: student, skill-id: skill-id }) err-not-found))
    )
    (map-set student-skills 
      { student: student, skill-id: skill-id }
      (merge skill { proficiency-level: new-level })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (verify-skill (student principal) (skill-id uint))
  (let
    (
      (skill (unwrap! (map-get? student-skills { student: student, skill-id: skill-id }) err-not-found))
      (endorsement-count (get-endorsement-count student skill-id))
    )
    (asserts! (>= endorsement-count u3) err-unauthorized)
    (map-set student-skills 
      { student: student, skill-id: skill-id }
      (merge skill { verified: true })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (remove-skill (skill-id uint))
  (let
    (
      (student tx-sender)
      (skill (unwrap! (map-get? student-skills { student: student, skill-id: skill-id }) err-not-found))
      (current-count (get-user-skills-count student))
    )
    (map-delete student-skills { student: student, skill-id: skill-id })
    (map-set user-skills-count student (if (> current-count u0) (- current-count u1) u0))
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (update-skill-category (skill-id uint) (new-category (string-ascii 50)))
  (let
    (
      (student tx-sender)
      (skill (unwrap! (map-get? student-skills { student: student, skill-id: skill-id }) err-not-found))
    )
    (map-set student-skills 
      { student: student, skill-id: skill-id }
      (merge skill { category: new-category })
    )
    (update-category-count new-category)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (register-category (category (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-none (map-get? skill-categories category)) err-already-exists)
    (map-set skill-categories category { active: true, skill-count: u0 })
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (toggle-platform-status)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (var-set platform-active (not (var-get platform-active)))
    (ok (var-get platform-active))
  )
)

;; Private functions
;; #[allow(unchecked_data)]
(define-private (update-endorser-stats (endorser principal))
  (let
    (
      (current-stats (get-endorser-stats endorser))
      (new-total (+ (get total-endorsements-given current-stats) u1))
      (new-reputation (+ (get reputation-score current-stats) u10))
    )
    (map-set endorser-stats endorser 
      {
        total-endorsements-given: new-total,
        reputation-score: new-reputation
      }
    )
  )
)

;; #[allow(unchecked_data)]
(define-private (update-user-reputation (user principal))
  (let
    (
      (current-rep (get-user-reputation user))
      (new-rep (+ current-rep u5))
    )
    (map-set user-reputation user new-rep)
  )
)

;; #[allow(unchecked_data)]
(define-private (update-category-count (category (string-ascii 50)))
  (let
    (
      (category-info (default-to { active: true, skill-count: u0 } (map-get? skill-categories category)))
      (new-count (+ (get skill-count category-info) u1))
    )
    (map-set skill-categories category 
      (merge category-info { skill-count: new-count })
    )
  )
)