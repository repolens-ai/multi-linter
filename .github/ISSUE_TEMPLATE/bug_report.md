name: Bug Report
description: Report a bug to help us improve
title: "[Bug] "
labels: type: bug
body:
  - type: markdown
    attributes:
      value: |
        ## Bug Description
        A clear and concise description of what the bug is.
  - type: textarea
    id: description
    attributes:
      label: Describe the bug
      placeholder: Describe what happened instead of what you expected
    validations:
      required: true
  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
      placeholder: |
        1.
        2.
        3.
    validations:
      required: true
  - type: textarea
    id: environment
    attributes:
      label: Environment
      placeholder: |
        - OS:
        - Docker version:
        - Multi-linter version:
