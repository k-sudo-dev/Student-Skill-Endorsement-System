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