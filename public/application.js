$(document).ready(function (){
    $('#hit_form').click(function () {
        $.ajax({
            type: 'POST',
            url: '/hit'
        }).done(function(msg) {
            $('#player-area').replaceWith(msg);
        });
        return false;
    })
    ;
});
