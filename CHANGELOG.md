# v1.2.1

* 2019-12-11 [da9e7fc](../../commit/da9e7fc) - __(GIGrave)__ Release 1.2.1 
* 2019-11-27 [d2589f9](../../commit/d2589f9) - __(Ilya Zhidkov)__ fix(xml template): check product description presence before size calc https://jira.railsc.ru/browse/BPC-15475 
* 2019-11-25 [bd08be3](../../commit/bd08be3) - __(Ilya Zhidkov)__ fix(sysloggable): optimizations + do not log every loaded turbo page https://jira.railsc.ru/browse/BPC-15697 

# v1.2.0

* 2019-11-27 [7f28861](../../commit/7f28861) - __(Alexey)__ fix: call method size for NilClass 
* 2019-11-21 [cdc20ff](../../commit/cdc20ff) - __(Alexey)__ feature: exclude products online stores 
https://jira.railsc.ru/browse/PC4-24156

* 2019-11-18 [f5ed0ec](../../commit/f5ed0ec) - __(Ilya Zhidkov)__ feature: configurate suitable products sql, preload associations https://jira.railsc.ru/browse/BPC-15475 
* 2019-11-19 [3f83ca7](../../commit/3f83ca7) - __(Ilya Zhidkov)__ chore: rename drone.yml 
* 2019-11-19 [0030433](../../commit/0030433) - __(Ilya Zhidkov)__ chore: lock oj gem 
* 2019-11-20 [83ef8aa](../../commit/83ef8aa) - __(Aleksey Bukin)__ Release 1.1.0 
* 2019-11-18 [9bc4a5e](../../commit/9bc4a5e) - __(Alexey)__ fix: add rubric to preloader 
* 2019-11-14 [8b98a17](../../commit/8b98a17) - __(Aleksey Bukin)__ feature(logs): сдвигает поле message в конец лога 
https://jira.railsc.ru/browse/SERVER-4743

* 2019-09-06 [487c336](../../commit/487c336) - __(Aleksey Bukin)__ feature(db): переносит дб подключение с мастера на слейв 
https://jira.railsc.ru/browse/PC4-23987

* 2019-10-29 [413ef23](../../commit/413ef23) - __(Alexey)__ feat: add product rubrics to turbo-page 
https://jira.railsc.ru/browse/PC4-23961

* 2019-09-06 [d512d46](../../commit/d512d46) - __(Aleksey Bukin)__ Release 1.0.0 
https://jira.railsc.ru/browse/PC4-23844

* 2019-09-05 [26e2bed](../../commit/26e2bed) - __(Aleksey Bukin)__ fix(templates): чинит название характеристики 
https://jira.railsc.ru/browse/PC4-23862

* 2019-09-04 [18d9952](../../commit/18d9952) - __(Aleksey Bukin)__ fix(templates): фиксит вывод описания 
если товар без характеристик то описание не выводилось

https://jira.railsc.ru/browse/PC4-23862

* 2019-09-04 [a64d15d](../../commit/a64d15d) - __(Aleksey Bukin)__ fix(tasks): добавляет connection direсt для курсора в таске 
https://jira.railsc.ru/browse/PC4-23844

* 2019-09-04 [a7d4b90](../../commit/a7d4b90) - __(Aleksey Bukin)__ fix(templates): исправит ошибки с выводом описания 
- [x] resque падал с undefined method `size' for nil:NilClass если products.description == null
- [x] у турбо страницы может не быть полного описания и анонса (но их всеравно нужно отправлять)
- [x] кол-во товаров при оптовой цене
- [x] direct курсор для поиска товаров

https://jira.railsc.ru/browse/PC4-23862

* 2019-08-29 [e3e76f5](../../commit/e3e76f5) - __(Aleksey Bukin)__ fix(traits): исправит баг с выводом характеристик 
- [x] если в характеристиках были служебные значения то выводилась меню Характеристики без характеристик
- [x] + фиксит баг с коннектом

https://jira.railsc.ru/browse/PC4-23844?focusedCommentId=173463&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-173463

https://jira.railsc.ru/browse/PC4-23862

* 2019-08-27 [8bcc939](../../commit/8bcc939) - __(Aleksey Bukin)__ feature(turbo_pages): Добавляет оптовую цену 
https://jira.railsc.ru/browse/PC4-23862

* 2019-08-23 [17c6956](../../commit/17c6956) - __(Aleksey Bukin)__ feature(turbo_pages): добавляет верстку для турбостраниц 
https://jira.railsc.ru/browse/PC4-23862

* 2019-05-14 [9983041](../../commit/9983041) - __(Aleksey Bukin)__ feature(turbo_pages): добавляет функционал турбо-страниц 
- [x] п.0 - Инициализация гема
- [x] п.1 - Конфиги
- [x] п.2 - Очередь на генерацию
- [x] п.3 - Финдер товаров
- [x] п.4 - Job на заполнение
- [x] п.5 - Таск запускающий наполнение очередей
- [x] п.6 - Класс генерации XML файла
- [x] п.7 - Job на генерацию файла
- [x] п.8 - Таск генерации файлов
- [x] п.9 - Класс отправки
- [x] п.10 - Класс отправки файла
- [x] п.11 - Job проверки
- [x] п.12 - Job делающий отправку
- [x] п.13 - Таск запускающий отправки
- [x] п.14 - Таск на заполнение

https://jira.railsc.ru/browse/PC4-23209

* 2019-05-07 [4a2d691](../../commit/4a2d691) - __(Mamedaliev Kirill)__ Initial commit 
