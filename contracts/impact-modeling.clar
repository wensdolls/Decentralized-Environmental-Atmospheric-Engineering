;; Impact Modeling Contract
;; Simulates atmospheric engineering effects

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_MODEL_NOT_FOUND (err u201))
(define-constant ERR_INVALID_PARAMETERS (err u202))

(define-data-var model-counter uint u0)

(define-map impact-models
  { model-id: uint }
  {
    project-id: uint,
    modeler: principal,
    co2-reduction: int,
    temperature-change: int,
    precipitation-change: int,
    confidence-level: uint,
    created-at: uint,
    validated: bool
  }
)

(define-map model-validations
  { model-id: uint, validator: principal }
  { approved: bool, timestamp: uint }
)

(define-public (create-impact-model
  (project-id uint)
  (co2-reduction int)
  (temperature-change int)
  (precipitation-change int)
  (confidence-level uint))
  (let ((model-id (+ (var-get model-counter) u1)))
    (asserts! (<= confidence-level u100) ERR_INVALID_PARAMETERS)
    (map-set impact-models
      { model-id: model-id }
      {
        project-id: project-id,
        modeler: tx-sender,
        co2-reduction: co2-reduction,
        temperature-change: temperature-change,
        precipitation-change: precipitation-change,
        confidence-level: confidence-level,
        created-at: block-height,
        validated: false
      }
    )
    (var-set model-counter model-id)
    (ok model-id)
  )
)

(define-public (validate-model (model-id uint))
  (let ((model (unwrap! (map-get? impact-models { model-id: model-id }) ERR_MODEL_NOT_FOUND)))
    (map-set model-validations
      { model-id: model-id, validator: tx-sender }
      { approved: true, timestamp: block-height }
    )
    (ok true)
  )
)

(define-public (finalize-model (model-id uint))
  (let ((model (unwrap! (map-get? impact-models { model-id: model-id }) ERR_MODEL_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get modeler model)) ERR_UNAUTHORIZED)
    (map-set impact-models
      { model-id: model-id }
      (merge model { validated: true })
    )
    (ok true)
  )
)

(define-read-only (get-impact-model (model-id uint))
  (map-get? impact-models { model-id: model-id })
)

(define-read-only (calculate-net-impact (model-id uint))
  (let ((model (unwrap! (map-get? impact-models { model-id: model-id }) ERR_MODEL_NOT_FOUND)))
    (ok {
      environmental-score: (+ (get co2-reduction model) (get temperature-change model)),
      confidence: (get confidence-level model)
    })
  )
)
