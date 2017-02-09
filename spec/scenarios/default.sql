--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.1
-- Dumped by pg_dump version 9.5.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = public, pg_catalog;

--
-- Data for Name: annotation_providers; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: annotation_providers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('annotation_providers_id_seq', 1, false);


--
-- Data for Name: annotations; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: annotations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('annotations_id_seq', 1, false);


--
-- Data for Name: branches; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO branches VALUES (1, 1, 11, 'master', true, '2017-02-07 15:32:31.58457', '2017-02-07 15:32:31.786746');
INSERT INTO branches VALUES (2, 2, 16, 'master', true, '2017-02-07 15:32:31.880997', '2017-02-07 15:32:31.881831');


--
-- Name: branches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('branches_id_seq', 2, true);


--
-- Data for Name: broadcasts; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: broadcasts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('broadcasts_id_seq', 1, false);


--
-- Data for Name: builds; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO builds VALUES (1, 1, '1', '2010-11-12 12:00:00', '2010-11-12 12:00:10', '2017-02-07 15:32:31.538957', '2017-02-07 15:32:31.538957', '---
:rvm:
- 1.8.7
- 1.9.2
:gemfile:
- test/Gemfile.rails-2.3.x
- test/Gemfile.rails-3.0.x
', 1, 1, 'failed', NULL, 1, 'User', 'push', NULL, NULL, NULL, 'master', NULL, '{2,3,4,5}', NULL, NULL);
INSERT INTO builds VALUES (6, 1, '2', '2010-11-12 12:30:00', '2010-11-12 12:30:20', '2017-02-07 15:32:31.665183', '2017-02-07 15:32:31.665183', '---
:rvm:
- 1.8.7
- 1.9.2
:gemfile:
- test/Gemfile.rails-2.3.x
- test/Gemfile.rails-3.0.x
', 3, 2, 'passed', NULL, 1, 'User', 'push', 'failed', NULL, NULL, 'master', NULL, '{7,8,9,10}', NULL, NULL);
INSERT INTO builds VALUES (11, 1, '3', '2010-11-12 13:00:00', NULL, '2017-02-07 15:32:31.763225', '2017-02-07 15:32:31.763225', '---
:rvm:
- 1.8.7
- 1.9.2
:gemfile:
- test/Gemfile.rails-2.3.x
- test/Gemfile.rails-3.0.x
', 5, 3, 'configured', NULL, 1, 'User', 'push', 'passed', NULL, NULL, 'master', NULL, '{12,13,14,15}', NULL, NULL);
INSERT INTO builds VALUES (16, 2, '1', '2010-11-11 12:00:00', '2010-11-11 12:00:05', '2017-02-07 15:32:31.873576', '2017-02-07 15:32:31.873576', '---
...
', 7, 4, 'failes', NULL, 2, 'User', 'push', NULL, NULL, NULL, 'master', NULL, '{17}', NULL, NULL);


--
-- Name: builds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('builds_id_seq', 1, false);


--
-- Data for Name: commits; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO commits VALUES (1, NULL, '1a738d9d6f297c105ae2', 'refs/heads/develop', 'master', 'add Gemfile', 'https://github.com/svenfuchs/minimal/compare/master...develop', '2010-11-12 11:50:00', 'Sven Fuchs', 'svenfuchs@artweb-design.de', 'Sven Fuchs', 'svenfuchs@artweb-design.de', '2017-02-07 15:32:31.442923', '2017-02-07 15:32:31.442923');
INSERT INTO commits VALUES (2, NULL, '62aae5f70ceee39123ef', NULL, 'master', 'the commit message 🤔', 'https://github.com/svenfuchs/minimal/compare/master...develop', '2011-11-11 11:11:11', 'Sven Fuchs', 'svenfuchs@artweb-design.de', 'Sven Fuchs', 'svenfuchs@artweb-design.de', '2017-02-07 15:32:31.478269', '2017-02-07 15:32:31.478269');
INSERT INTO commits VALUES (3, NULL, '91d1b7b2a310131fe3f8', 'refs/heads/master', 'master', 'Bump to 0.0.22', 'https://github.com/svenfuchs/minimal/compare/master...develop', '2010-11-12 12:25:00', 'Sven Fuchs', 'svenfuchs@artweb-design.de', 'Sven Fuchs', 'svenfuchs@artweb-design.de', '2017-02-07 15:32:31.641449', '2017-02-07 15:32:31.641449');
INSERT INTO commits VALUES (4, NULL, '62aae5f70ceee39123ef', NULL, 'master', 'the commit message 🤔', 'https://github.com/svenfuchs/minimal/compare/master...develop', '2011-11-11 11:11:11', 'Sven Fuchs', 'svenfuchs@artweb-design.de', 'Sven Fuchs', 'svenfuchs@artweb-design.de', '2017-02-07 15:32:31.644716', '2017-02-07 15:32:31.644716');
INSERT INTO commits VALUES (5, NULL, 'add057e66c3e1d59ef1f', 'refs/heads/master', 'master', 'unignore Gemfile.lock', 'https://github.com/svenfuchs/minimal/compare/master...develop', '2010-11-12 12:55:00', 'Sven Fuchs', 'svenfuchs@artweb-design.de', 'Sven Fuchs', 'svenfuchs@artweb-design.de', '2017-02-07 15:32:31.740764', '2017-02-07 15:32:31.740764');
INSERT INTO commits VALUES (6, NULL, '62aae5f70ceee39123ef', NULL, 'master', 'the commit message 🤔', 'https://github.com/svenfuchs/minimal/compare/master...develop', '2011-11-11 11:11:11', 'Sven Fuchs', 'svenfuchs@artweb-design.de', 'Sven Fuchs', 'svenfuchs@artweb-design.de', '2017-02-07 15:32:31.744123', '2017-02-07 15:32:31.744123');
INSERT INTO commits VALUES (7, NULL, '565294c05913cfc23230', 'refs/heads/master', 'master', 'Update Capybara', 'https://github.com/svenfuchs/minimal/compare/master...develop', '2010-11-11 11:55:00', 'Jose Valim', 'jose@email.com', 'Jose Valim', 'jose@email.com', '2017-02-07 15:32:31.848326', '2017-02-07 15:32:31.848326');
INSERT INTO commits VALUES (8, NULL, '62aae5f70ceee39123ef', NULL, 'master', 'the commit message 🤔', 'https://github.com/svenfuchs/minimal/compare/master...develop', '2011-11-11 11:11:11', 'Sven Fuchs', 'svenfuchs@artweb-design.de', 'Sven Fuchs', 'svenfuchs@artweb-design.de', '2017-02-07 15:32:31.851499', '2017-02-07 15:32:31.851499');


--
-- Name: commits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('commits_id_seq', 8, true);


--
-- Data for Name: coupons; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: coupons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('coupons_id_seq', 1, false);


--
-- Data for Name: crons; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: crons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('crons_id_seq', 1, false);


--
-- Data for Name: emails; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: emails_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('emails_id_seq', 1, false);


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: invoices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('invoices_id_seq', 1, false);


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO jobs VALUES (2, 1, 1, 1, 'Build', 'builds.linux', 'Job::Test', 'failed', '1.1', '---
:rvm: 1.8.7
:gemfile: test/Gemfile.rails-2.3.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', 'ruby3.worker.travis-ci.org:travis-ruby-4', '2010-11-12 12:00:00', '2010-11-12 12:00:10', '2017-02-07 15:32:31.54623', '2017-02-07 15:32:31.630256', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (3, 1, 1, 1, 'Build', 'builds.linux', 'Job::Test', 'failed', '1.2', '---
:rvm: 1.8.7
:gemfile: test/Gemfile.rails-3.0.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', NULL, '2010-11-12 12:00:00', '2010-11-12 12:00:10', '2017-02-07 15:32:31.561812', '2017-02-07 15:32:31.632819', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (4, 1, 1, 1, 'Build', 'builds.linux', 'Job::Test', 'failed', '1.3', '---
:rvm: 1.9.2
:gemfile: test/Gemfile.rails-2.3.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', NULL, '2010-11-12 12:00:00', '2010-11-12 12:00:10', '2017-02-07 15:32:31.566515', '2017-02-07 15:32:31.634834', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (5, 1, 1, 1, 'Build', 'builds.linux', 'Job::Test', 'failed', '1.4', '---
:rvm: 1.9.2
:gemfile: test/Gemfile.rails-3.0.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', NULL, '2010-11-12 12:00:00', '2010-11-12 12:00:10', '2017-02-07 15:32:31.571212', '2017-02-07 15:32:31.63684', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (7, 1, 3, 6, 'Build', 'builds.linux', 'Job::Test', 'passed', '2.1', '---
:rvm: 1.8.7
:gemfile: test/Gemfile.rails-2.3.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', 'ruby3.worker.travis-ci.org:travis-ruby-4', '2010-11-12 12:30:00', '2010-11-12 12:30:20', '2017-02-07 15:32:31.668033', '2017-02-07 15:32:31.729769', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (8, 1, 3, 6, 'Build', 'builds.linux', 'Job::Test', 'passed', '2.2', '---
:rvm: 1.8.7
:gemfile: test/Gemfile.rails-3.0.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', NULL, '2010-11-12 12:30:00', '2010-11-12 12:30:20', '2017-02-07 15:32:31.672921', '2017-02-07 15:32:31.732197', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (9, 1, 3, 6, 'Build', 'builds.linux', 'Job::Test', 'passed', '2.3', '---
:rvm: 1.9.2
:gemfile: test/Gemfile.rails-2.3.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', NULL, '2010-11-12 12:30:00', '2010-11-12 12:30:20', '2017-02-07 15:32:31.679046', '2017-02-07 15:32:31.734183', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (10, 1, 3, 6, 'Build', 'builds.linux', 'Job::Test', 'passed', '2.4', '---
:rvm: 1.9.2
:gemfile: test/Gemfile.rails-3.0.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', NULL, '2010-11-12 12:30:00', '2010-11-12 12:30:20', '2017-02-07 15:32:31.683346', '2017-02-07 15:32:31.736176', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (12, 1, 5, 11, 'Build', 'builds.linux', 'Job::Test', 'configured', '3.1', '---
:rvm: 1.8.7
:gemfile: test/Gemfile.rails-2.3.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', 'ruby3.worker.travis-ci.org:travis-ruby-4', '2010-11-12 13:00:00', NULL, '2017-02-07 15:32:31.766143', '2017-02-07 15:32:31.827348', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (13, 1, 5, 11, 'Build', 'builds.linux', 'Job::Test', 'configured', '3.2', '---
:rvm: 1.8.7
:gemfile: test/Gemfile.rails-3.0.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', 'ruby3.worker.travis-ci.org:travis-ruby-4', '2010-11-12 13:00:00', NULL, '2017-02-07 15:32:31.770922', '2017-02-07 15:32:31.833755', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (14, 1, 5, 11, 'Build', 'builds.linux', 'Job::Test', 'configured', '3.3', '---
:rvm: 1.9.2
:gemfile: test/Gemfile.rails-2.3.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', 'ruby3.worker.travis-ci.org:travis-ruby-4', '2010-11-12 13:00:00', NULL, '2017-02-07 15:32:31.778072', '2017-02-07 15:32:31.839513', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (15, 1, 5, 11, 'Build', 'builds.linux', 'Job::Test', 'configured', '3.4', '---
:rvm: 1.9.2
:gemfile: test/Gemfile.rails-3.0.x
:language: ruby
:group: stable
:dist: precise
:os: linux
', 'ruby3.worker.travis-ci.org:travis-ruby-4', '2010-11-12 13:00:00', NULL, '2017-02-07 15:32:31.782683', '2017-02-07 15:32:31.844993', NULL, false, 1, 'User', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO jobs VALUES (17, 2, 7, 16, 'Build', 'builds.linux', 'Job::Test', 'failes', '1.1', '---
:language: ruby
:group: stable
:dist: precise
:os: linux
', 'ruby3.worker.travis-ci.org:travis-ruby-4', '2010-11-11 12:00:00', '2010-11-11 12:00:05', '2017-02-07 15:32:31.876677', '2017-02-07 15:32:31.89617', NULL, false, 2, 'User', NULL, NULL, NULL, NULL, NULL, NULL);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('jobs_id_seq', 1, false);


--
-- Data for Name: memberships; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: memberships_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('memberships_id_seq', 1, false);


--
-- Data for Name: organizations; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: organizations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('organizations_id_seq', 1, false);


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('permissions_id_seq', 1, false);


--
-- Data for Name: plans; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('plans_id_seq', 1, false);


--
-- Data for Name: repositories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO repositories VALUES (1, 'minimal', 'http://github.com/svenfuchs/minimal', '2011-01-30 05:25:00', '2017-02-07 15:32:31.749485', 6, '2', '2010-11-12 12:30:00', '2010-11-12 12:30:20', 'svenfuchs', 'svenfuchs@artweb-design.de', true, NULL, NULL, 1, 'User', false, 'passed', 1, NULL, NULL, NULL, 4, NULL, NULL);
INSERT INTO repositories VALUES (2, 'enginex', 'http://github.com/josevalim/enginex', '2011-01-30 05:25:00', '2017-02-07 15:32:31.857878', 2, '2', '2017-02-07 15:32:31.395308', '2017-02-07 15:32:31.395322', 'josevalim', 'josevalim@email.com', true, NULL, NULL, 2, 'User', false, 'passed', 2, NULL, NULL, NULL, 2, NULL, NULL);


--
-- Name: repositories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('repositories_id_seq', 2, true);


--
-- Data for Name: requests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO requests VALUES (1, 1, 2, 'created', NULL, NULL, 'the-token', NULL, NULL, NULL, '2017-02-07 15:32:31.481022', '2017-02-07 15:32:31.481022', 'push', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO requests VALUES (2, 2, 4, 'created', NULL, NULL, 'the-token', NULL, NULL, NULL, '2017-02-07 15:32:31.646507', '2017-02-07 15:32:31.646507', 'push', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO requests VALUES (3, 2, 6, 'created', NULL, NULL, 'the-token', NULL, NULL, NULL, '2017-02-07 15:32:31.745785', '2017-02-07 15:32:31.745785', 'push', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO requests VALUES (4, 2, 8, 'created', NULL, NULL, 'the-token', NULL, NULL, NULL, '2017-02-07 15:32:31.85307', '2017-02-07 15:32:31.85307', 'push', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- Name: requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('requests_id_seq', 4, true);


--
-- Name: shared_builds_tasks_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('shared_builds_tasks_seq', 17, true);


--
-- Data for Name: ssl_keys; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: ssl_keys_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('ssl_keys_id_seq', 1, false);


--
-- Data for Name: stars; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: stars_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('stars_id_seq', 1, false);


--
-- Data for Name: stripe_events; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: subscriptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('subscriptions_id_seq', 1, false);


--
-- Data for Name: tokens; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO tokens VALUES (1, 1, 'cq4Wq9mcpki8LsCyM6Po', '2017-02-07 15:32:31.37185', '2017-02-07 15:32:31.37185');
INSERT INTO tokens VALUES (2, 1, '7wuCdxL8Eg6EtSEUZP6u', '2017-02-07 15:32:31.376247', '2017-02-07 15:32:31.376247');
INSERT INTO tokens VALUES (3, 2, 'xFi5SqjwBfBSyxfFxEa8', '2017-02-07 15:32:31.39198', '2017-02-07 15:32:31.39198');
INSERT INTO tokens VALUES (4, 2, 'hPheAx4Qs1RKp2ddP6sh', '2017-02-07 15:32:31.393486', '2017-02-07 15:32:31.393486');


--
-- Name: tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('tokens_id_seq', 4, true);


--
-- Data for Name: urls; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: urls_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('urls_id_seq', 1, false);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO users VALUES (1, 'Sven Fuchs', 'svenfuchs', 'sven@fuchs.com', '2017-02-07 15:32:31.367356', '2017-02-07 15:32:31.367356', false, NULL, '--ENCR--3diYnpGA/4eAjSNGmgh4CLmHgxT9xj6EnRF7vi2axF9hODEyNTYxODIwOWE5ZTlj', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO users VALUES (2, 'Sven Fuchs', 'josevalim', 'sven@fuchs.com', '2017-02-07 15:32:31.390483', '2017-02-07 15:32:31.390483', false, NULL, '--ENCR--f8AYe1iMBaKYoJVCzecJRxR12PB4dV5thT/4ImHFUK5lYzdkZmEzZWIzZGExOWNh', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('users_id_seq', 2, true);


--
-- PostgreSQL database dump complete
--
