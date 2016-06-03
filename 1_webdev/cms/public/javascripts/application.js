$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This cannot be undone!");
    if (ok) {
      // this.submit(); //doesn't suggest using confirm box
      var form = $(this);
      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });
       
      request.done(function(data, textStatus, jqXHR){
        form.parent("li").remove()
      });
    };
  });
  
  // $("form.duplicate").submit(function(event) {
  //   event.preventDefault();
  //   event.stopPropagation();

  //   var ok = confirm("Are you sure? This cannot be undone!");
  //     if (ok) {
  //     this.submit();  
  // //     var form = $(this);
  // //     var request = $.ajax({
  // //       url: form.attr("action"),
  // //       method: form.attr("method")
  // //       });
       
  // //     request.done(function(data, textStatus, jqXHR){
  // //       form.parent("li").duplicate()
  // //       });
  //     };
  //   });
 
 });