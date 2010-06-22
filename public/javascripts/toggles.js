function toggleCheckboxes() {
  // written by Daniel P 3/21/07
  // toggle all checkboxes found on the page
  var inputlist = document.getElementsByTagName("input");

  for (i = 0; i < inputlist.length; i++) {
    if ( inputlist[i].getAttribute("type") == 'checkbox' ) { // look only at input elements that are checkboxes
      if (inputlist[i].checked) inputlist[i].checked = false
      else inputlist[i].checked = true;
      }
    }
  }
