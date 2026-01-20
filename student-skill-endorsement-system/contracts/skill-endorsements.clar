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