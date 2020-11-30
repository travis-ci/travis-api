$(document).ready(function(){
  $(function() {
    $('.datepicker').datepicker({
			dateFormat: 'yy-mm-dd',
			maxDate: '0',
			onSelect: function(dateText, inst){
				$("#report_to").datepicker("option","minDate",
					$("#report_from").datepicker("getDate"));
			}
	  });
	
	  $('.datepicker-no-max').datepicker({
		  dateFormat: 'yy-mm-dd'
	  });
  });
})
