# Student Skill Endorsement Smart Contract

A peer-to-peer system for verifying and endorsing student skills on the blockchain.

## Features

- Skill profile management
- Peer endorsements with comments
- Proficiency level tracking
- Endorsement counting
- Self-endorsement prevention

## Contract Functions

### Public Functions

- `add-skill` - Add a skill to your profile
- `endorse-skill` - Endorse another student's skill
- `update-proficiency` - Update your skill proficiency level

### Read-Only Functions

- `get-student-skill` - Get skill details
- `get-endorsement` - Get specific endorsement
- `get-endorsement-count` - Get total endorsements for a skill
- `get-user-skills-count` - Get total skills for a user
- `get-skill-nonce` - Get current skill counter

## Usage

Deploy with Clarinet to enable peer skill verification.