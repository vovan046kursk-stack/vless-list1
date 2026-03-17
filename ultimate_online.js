(function () {
    'use strict';

    function start() {
        console.log('ULTIMATE START');

        Lampa.Component.add('ultimate_online', {
            name: 'Ultimate',

            init: function () {
                this.render();
            },

            render: function () {
                this.activity.loader(false);
                this.empty();

                this.append(
                    '<div style="padding:20px">' +
                    '<h1>Ultimate работает</h1>' +
                    '<button id="btn">OK</button>' +
                    '</div>'
                );

                var btn = document.getElementById('btn');
                if (btn) {
                    btn.onclick = function () {
                        alert('РАБОТАЕТ 💀');
                    };
                }
            }
        });

        Lampa.Menu.add({
            title: 'Ultimate',
            component: 'ultimate_online',
            icon: 'movie'
        });
    }

    if (window.appready) {
        start();
    } else {
        window.addEventListener('appready', start);
    }

})();
