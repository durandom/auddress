var ClueField = Behavior.create({
    initialize : function() {
        this._clue(this.element);
    } ,
    _clue : function(element) {
        if(element.value == '') {
            element.value = element.title;
            element.removeClassName('clue');
            element.addClassName('clued');
        }
    },
    _unclue : function(element) {
        if(element.hasClassName('clued')) {
            element.value = '';
            element.removeClassName('clued');
            element.addClassName('clue');
        }
    },
    onfocus : function(event) {
        element = Event.element(event);
        this._unclue(element);
    },
    onblur : function(event) {
        element = Event.element(event);
        this._clue(this.element);
    }
});

// called by remote_form_for :before option
// FIXME: eliminate all remote_forms and do this with behaviors
function RemoveClues(the_form) {
    the_form.getElementsBySelector('.clued').each(function(e) {
        e.value = '';
    })
}

Event.addBehavior.reassignAfterAjax = true;
Event.addBehavior({
    'form.clued input.clue': ClueField(),
    'form.clued a.plus:click' : function(event) {
        // from lowpro.js Event.addBehavior.reload - can we do this better?
        // needed for dynamic forms, where we add an address or email
        var ab = Event.addBehavior;
        ab.unload();
        ab.load(ab.rules);
    },
    'form.clued img.photo.edit:click' : function(event) {
        $('postcard').toggle();
    }
});

 
