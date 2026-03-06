name: Feature Request
description: Suggest a new feature or enhancement
title: "[Feature] "
labels: type: enhancement
body:
  - type: markdown
    attributes:
      value: |
        ## Feature Description
        A clear and concise description of the feature you'd like to add.
  - type: textarea
    id: description
    attributes:
      label: Feature Description
      placeholder: Describe the feature you're requesting
    validations:
      required: true
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives
      placeholder: Describe any alternatives you've considered
  - type: textarea
    id: additional
    attributes:
      label: Additional Context
      placeholder: Add any other context about the feature request here
