#lang racket ; CSC324 — 2023W — Assignment 1 - Evo Design and Testing

; • Evo: Eager By-Value Stateful Evaluator for an Extended Lambda Calculus

; Task: understand the syntax and semantics of the language LCO described below,
; then create a good test suite for an evaluator of LCO named evo which you will
; then implement in A1.evo.rkt

(require "A1.evo.rkt"
         rackunit)

; We'll refer to the language being interpreted in this part as “LCO”.

; · Terms in LCO

; The grammar of “terms” [along with how we'll refer to them] in LCO is:
;   term = (λ (<parameter-identifier>) <body-term> ... <result-term>) [“λ term”]
;        | (<function-term> <argument-term>)  [“function call term”]
;        | (set! <variable-identifier> <update-term>)  [“assignment term”]
;        | <identifier>  [“variable term”]
;        | <literal>  [“literal term”]

; · Values, Closures, and Environments in LCO

; LCO has the same values, closures, and environments, as LCE except that
; binding values in environments are now stored inside mutable boxes
; (a datatype for replaceable values).

(check-true (box? #&108)) ; a literal (but immutable) box
(check-equal? (box 108) #&108) ; the mutable box constructor from a value
(check-equal? (unbox #&108) 108) ; extracting the value from a box
(check-equal? (let ((b (box 108)))
                (set-box! b 324)
                (unbox b))
              324)

; Notice that racket procedures are valid literal terms in LCA and LCE/LCO:
#;(check-equal? (eva add1) add1)
#;(check-equal? (eve add1) add1)
#;(check-equal? (evo add1) add1)

; We'll give a semantics to function call where the function term evaluates to
; a racket procedure. A convenient way to embed a procedure in a term is to use
; “quasiquotating” which is like quoting but can be escaped out of (“unquoted”).
; The quasiquoting character is the backwards single-quote, aka back-tick, and
; the unquoting character is the upside-down quasiquote, aka comma:
(check-equal? '(add1 2) (list 'add1 2))
(check-not-equal? '(add1 2) (list add1 2))
(check-equal? '(add1 2) `(add1 2)) ; no change since no unquoting
(check-true (symbol? (first `(add1 2))))
(check-equal? `(,add1 2) (list add1 2)) ; use variable's value
(check-true (procedure? (first `(,add1 2))))

; · Semantics of LCO

; Evaluation still takes a term and an index of an appropriate environment.

; Evaluation of a value or λ is as for LCE.

; Evaluation of a variable is as for LCE (with the extra step of extracting
; its current value from the box it is stored in).

; Evaluation of function call allows the value of the function term to be a
; racket procedure, in which case the evaluation is the result of calling that
; procedure on the value of the argument term.

; Evaluation of function call when the value of the function term is (an index
; of) a closure is evaluation (in the new environment as described in LCE) of
; each body term (in order) followed by producing the value of the result term.

; Evaluation of assignment is evaluation of the update term in the current
; environment, replacement of the variable's value in the current environment,
; producing the void value (which the implementation names and exports as Void).

; · Design and Testing

; Create a good test suite for evo, with a comment above each test case giving
; a clear rationale for its inclusion.

; Also include test cases for any significant helper functions you create
; (e.g. a recursive function is likely to be significant) to aid debugging, and
; export those helper functions from A1.evo.rkt so they can be referenced here.

; Illustrate embedding racket function call, boxed values in environments, and
; result value of assignment.
(check-equal? (evo `((λ (x) (set! x (,add1 x))) 1))
                `(,Void #hash((E1 . ((x #&2) E0))
                              (λ0 . ((λ (x) (set! x (,add1 x))) E0)))))
