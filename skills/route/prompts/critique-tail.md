--- PLAN.md END ---

Report ONLY via the structured output schema:

- `verdict`: "agree" only if you verified the plan's repo/live claims and
  found no blocker and no major; otherwise "objections".
- `coverage.inspected`: every path you actually opened.
- `coverage.not_inspected`: high-risk surfaces you did NOT open — name them
  honestly; an empty list claims you saw everything.
- `new_objections[]`: severity, anchor_type (repo|spec|plan), anchor, point,
  suggestion (null if none).
- `notes`: anything true and important that fits no field, else null.
