(function () {
    'use strict';

    function startPlugin() {

        console.log('ULTIMATE FULL FIX');

        if (!window.Lampa || !Lampa.Component) return;

        Lampa.Component.add('ultimate_online', {

            init: function () {
                this.activity.loader(false);
                this.render();
            },

            render: function () {
                this.empty();

                this.append(
                    '<div style="padding:20px">' +
                    '<h1>Ultimate работает</h1>' +
                    '<button id="btn">Проверка</button>' +
                    '</div>'
                );

                var btn = document.getElementById('btn');
                if (btn) {
                    btn.onclick = function () {
                        alert('ВСЁ РАБОТАЕТ 💀');
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

    // 💣 ГАРАНТИРОВАННЫЙ ХУК
    if (window.Lampa && Lampa.Listener) {
        Lampa.Listener.follow('app', function (e) {
            if (e.type === 'ready') {
                startPlugin();
            }
        });
    } else {
        setTimeout(startPlugin, 2000);
    }

})();
