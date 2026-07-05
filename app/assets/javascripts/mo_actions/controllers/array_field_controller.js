(function () {
  class ArrayFieldController extends (window.Stimulus && window.Stimulus.Controller || class {}) {
    add(event) {
      event.preventDefault()
      addRow(this.element)
    }

    remove(event) {
      event.preventDefault()
      removeRow(event.target)
    }

    moveUp(event) {
      event.preventDefault()
      moveRow(event.target, "up")
    }

    moveDown(event) {
      event.preventDefault()
      moveRow(event.target, "down")
    }
  }

  function controllerFor(element) {
    return element.closest("[data-controller~='array-field']")
  }

  function rowsContainer(controller) {
    return controller.querySelector("[data-array-field-target~='rows']")
  }

  function emptyMarker(controller) {
    return controller.querySelector("[data-array-field-target~='emptyMarker']")
  }

  function template(controller) {
    return controller.querySelector("[data-array-field-target~='template']")
  }

  function updateEmptyMarker(controller) {
    const marker = emptyMarker(controller)
    if (marker) marker.disabled = rowsContainer(controller).children.length > 0
  }

  function addRow(controller) {
    const fragment = template(controller).content.cloneNode(true)
    rowsContainer(controller).appendChild(fragment)
    updateEmptyMarker(controller)
  }

  function removeRow(button) {
    const controller = controllerFor(button)
    button.closest("[data-array-field-target~='row']").remove()
    updateEmptyMarker(controller)
  }

  function moveRow(button, direction) {
    const row = button.closest("[data-array-field-target~='row']")
    const sibling = direction === "up" ? row.previousElementSibling : row.nextElementSibling
    if (!sibling) return

    if (direction === "up") {
      row.parentNode.insertBefore(row, sibling)
    } else {
      row.parentNode.insertBefore(sibling, row)
    }
  }

  function handleClick(event) {
    const actionButton = event.target.closest("[data-action]")
    if (!actionButton || !actionButton.dataset.action.includes("array-field#")) return

    const controller = controllerFor(actionButton)
    if (!controller) return

    if (actionButton.dataset.action.includes("array-field#add")) {
      event.preventDefault()
      addRow(controller)
    } else if (actionButton.dataset.action.includes("array-field#remove")) {
      event.preventDefault()
      removeRow(actionButton)
    } else if (actionButton.dataset.action.includes("array-field#moveUp")) {
      event.preventDefault()
      moveRow(actionButton, "up")
    } else if (actionButton.dataset.action.includes("array-field#moveDown")) {
      event.preventDefault()
      moveRow(actionButton, "down")
    }
  }

  if (window.Stimulus) {
    window.Stimulus.register("array-field", ArrayFieldController)
  } else {
    document.addEventListener("click", handleClick)
  }
})()
