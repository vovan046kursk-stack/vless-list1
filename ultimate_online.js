(function () {
    'use strict';

    function initPlugin() {

        console.log('ULTIMATE INIT');

        if (!window.Lampa) return;

        Lampa.Component.add('ultimate_online', {

            init: function () {
                this.render();
            },

            render: function () {
                this.activity.loader(false);
                this.empty();

                this.append(
                    '<div style="padding:20px">' +
                    '<h1>Ultimate работает</h1>' +
                    '<button id="btn">Проверка</button>' +
                    '</div>'
                );

                setTimeout(function () {
                    var btn = document.getElementById('btn');
                    if (btn) {
                        btn.onclick = function () {
                            alert('ПЛАГИН ЖИВОЙ');
                        };
                    }
                }, 300);
            }
        });

        Lampa.Menu.add({
            title: 'Ultimate',
            component: 'ultimate_online',
            icon: 'movie'
        });
    }

    function start() {
        try {
            initPlugin();
        } catch (e) {
            console.log('PLUGIN ERROR', e);
        }
    }

    if (window.Lampa) {
        start();
    }

    window.addEventListener('lampa:ready', start);

})();
