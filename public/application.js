$(document).ready(function (){
    $(document).on('click', '#hit_form input', function() {
        $.ajax({
            type: 'POST',
            url: '/hit'
        }).done(function(msg) {
            $('#game-area').replaceWith(msg);
        });
        return false;
    });

    $(document).on('click', '#stay_form input', function() {
        $.ajax({
            type: 'POST',
            url: '/stay'
        }).done(function(msg) {
            $('#game-area').replaceWith(msg);
        });
        return false;
    });
});
