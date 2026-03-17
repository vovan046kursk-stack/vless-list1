(function () {
    'use strict';

    if (!window.Lampa) return;

    Lampa.Plugin.add({
        name: 'ultimate_online',

        init: function () {

            console.log('PLUGIN INIT OK');

            Lampa.Component.add('ultimate_online_component', {

                init: function () {
                    this.activity.loader(false);
                    this.render();
                },

                render: function () {
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
                            alert('ВСЁ РАБОТАЕТ 💀');
                        };
                    }
                }
            });

            Lampa.Menu.add({
                title: 'Ultimate',
                component: 'ultimate_online_component',
                icon: 'movie'
            });
        }
    });

})();
