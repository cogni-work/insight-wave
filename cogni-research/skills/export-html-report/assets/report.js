/**
 * Report Navigation JavaScript
 * Architecture: LoadingProgress + TabRouter + SectionNav + EntityFocusTracker
 *              + WikilinkPreview + KanbanBoard + GraphView + LandingPage
 *
 * LoadingProgress:      Deferred module init with progress overlay and browser yields
 * TabRouter:            Hash-based tab switching, right panel management, entity routing
 * SectionNav:           Left sidebar section navigation within tabs
 * EntityFocusTracker:   Scroll-driven entity highlighting and graph sync
 * WikilinkPreview:      Obsidian-style hover previews for entity links
 * KanbanBoard:          Trend Landscape kanban grid (horizons × dimensions)
 * GraphView:            D3 force-directed entity relationship graph
 */

// ============================================================
// Shared Utilities
// ============================================================
function escapeHtml(text) {
    if (!text || typeof text !== 'string') return '';
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ============================================================
// LoadingProgress — Orchestrates deferred module initialization
// with browser yields between each step so the loading overlay
// can actually paint and update.
// ============================================================
(function() {
    'use strict';

    var TOTAL_STEPS = 6;
    var current = 0;
    var overlay = document.getElementById('report-loading-overlay');
    var bar = document.getElementById('loading-bar');
    var detail = document.getElementById('loading-detail');
    var statusEl = overlay ? overlay.querySelector('.loading-status') : null;

    function step(label) {
        current++;
        if (detail) detail.textContent = label;
        if (bar) bar.style.width = Math.round((current / TOTAL_STEPS) * 100) + '%';

        if (current >= TOTAL_STEPS) finish();
    }

    function finish() {
        if (!overlay) return;
        overlay.classList.add('fade-out');
        overlay.addEventListener('transitionend', function() {
            if (overlay.parentNode) overlay.parentNode.removeChild(overlay);
        });
        // Fallback for prefers-reduced-motion (transition won't fire)
        setTimeout(function() {
            if (overlay && overlay.parentNode) overlay.parentNode.removeChild(overlay);
        }, 600);
    }

    // Chain module inits with setTimeout(0) between each so the browser
    // can paint the progress bar updates between steps.
    function run() {
        if (statusEl && typeof GRAPH_DATA !== 'undefined' && GRAPH_DATA && GRAPH_DATA.nodes) {
            var tpl = (typeof UI_TRANSLATIONS !== 'undefined' && UI_TRANSLATIONS.loading_entities)
                ? UI_TRANSLATIONS.loading_entities
                : 'Loading {0} entities\u2026';
            statusEl.textContent = tpl.replace('{0}', GRAPH_DATA.nodes.length);
        }

        var steps = [
            function() { if (window.TabRouter) window.TabRouter.init(); },
            function() { if (window.SectionNav) window.SectionNav.init(); },
            function() { if (window.EntityFocusTracker) window.EntityFocusTracker.init(); },
            function() { if (window.WikilinkPreview) window.WikilinkPreview.init(); },
            function() { if (window.KanbanBoard) window.KanbanBoard.init(); },
        ];
        var stepLabels = ['Navigation', 'Section nav', 'Entity tracker', 'Previews', 'Kanban'];

        function runStep(i) {
            if (i >= steps.length) {
                // GraphView is async (D3 CDN load) — step called from inside its init
                try { if (window.GraphView) window.GraphView.init(); }
                catch (e) { console.error('GraphView init failed:', e); step('Graph view'); }
                return;
            }
            setTimeout(function() {
                try { steps[i](); } catch (e) { console.error('Init step failed:', e); }
                step(stepLabels[i]);
                runStep(i + 1);
            }, 0);
        }

        runStep(0);
    }

    var hasRun = false;
    function safeRun() {
        if (hasRun) return;
        hasRun = true;
        run();
    }

    // Skip auto-init when in landing-mode (LandingPage module triggers run later)
    function autoInit() {
        if (document.body.classList.contains('landing-mode')) return;
        safeRun();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', autoInit);
    } else {
        autoInit();
    }

    window.LoadingProgress = { step: step, run: safeRun };
})();


// ============================================================
// TabRouter — Tab switching, dropdown, and entity routing
// ============================================================
(function() {
    'use strict';

    var CONFIG = {
        scrollOffset: 80,
        backToTopThreshold: 300,
        scrollThrottle: 100
    };

    // All content tabs (main + entity + appendix)
    var MAIN_TABS = [
        'overview', 'synthesis', 'megatrends', 'trends',
        'findings', 'claims', 'concepts',
        'questions', 'methodology', 'citations', 'sources'
    ];

    // Tabs that live in the Anhang dropdown
    var APPENDIX_TABS = ['questions', 'methodology', 'citations', 'sources'];

    // Entity prefix → tab mapping (all entities now route to main tabs)
    var MAIN_ENTITY_MAP = {
        'synthesis-': 'synthesis',
        'megatrend-': 'megatrends',
        'trend-': 'trends',
        'portfolio-': 'trends',
        'finding-': 'findings',
        'claim-': 'claims',
        'concept-': 'concepts',
        'question-': 'questions',
        'dimension-': 'questions',
        'dim-': 'questions',
        'source-': 'sources',
        'citation-': 'citations'
    };

    var currentTab = 'overview';

    function init() {
        // Bind main tab buttons (excluding dropdown trigger)
        document.querySelectorAll('.navbar-tab:not(.navbar-dropdown-trigger)').forEach(function(btn) {
            btn.addEventListener('click', function() {
                if (btn.dataset.tab) {
                    activateTab(btn.dataset.tab);
                    history.pushState(null, null, '#' + btn.dataset.tab);
                }
            });
        });

        // Bind Anhang dropdown trigger
        var dropdownTrigger = document.querySelector('.navbar-dropdown-trigger');
        if (dropdownTrigger) {
            dropdownTrigger.addEventListener('click', function(e) {
                e.stopPropagation();
                var dropdown = this.closest('.navbar-dropdown');
                if (dropdown) dropdown.classList.toggle('open');
            });
        }

        // Close dropdown on outside click
        document.addEventListener('click', function() {
            document.querySelectorAll('.navbar-dropdown.open').forEach(function(d) {
                d.classList.remove('open');
            });
        });

        // Bind dropdown items
        document.querySelectorAll('.navbar-dropdown-item').forEach(function(item) {
            item.addEventListener('click', function(e) {
                e.stopPropagation();
                var tabId = item.dataset.tab;
                activateTab(tabId);
                history.pushState(null, null, '#' + tabId);
                // Close dropdown
                var dropdown = item.closest('.navbar-dropdown');
                if (dropdown) dropdown.classList.remove('open');
            });
        });

        // Bind overview cards
        document.querySelectorAll('.overview-card[data-navigate]').forEach(function(card) {
            card.addEventListener('click', function() {
                var target = card.dataset.navigate;
                activateTab(target);
                history.pushState(null, null, '#' + target);
            });
        });

        // Bind hamburger menu
        var hamburger = document.querySelector('.navbar-hamburger');
        if (hamburger) {
            hamburger.addEventListener('click', function() {
                var tabs = document.querySelector('.navbar-tabs');
                if (tabs) tabs.classList.toggle('mobile-open');
            });
        }

        // Back-to-top button
        var backToTop = document.getElementById('back-to-top');
        if (backToTop) {
            backToTop.addEventListener('click', function(e) {
                e.preventDefault();
                window.scrollTo({ top: 0, behavior: 'smooth' });
            });
        }

        // Scroll handler for back-to-top
        var throttledScroll = throttle(function() {
            var btn = document.getElementById('back-to-top');
            if (btn) {
                btn.classList.toggle('visible', window.scrollY > CONFIG.backToTopThreshold);
            }
        }, CONFIG.scrollThrottle);
        window.addEventListener('scroll', throttledScroll, { passive: true });

        // Handle initial hash
        var hash = window.location.hash.replace('#', '') || 'overview';
        handleHash(hash);

        // Handle hash changes
        window.addEventListener('hashchange', function() {
            handleHash(window.location.hash.replace('#', ''));
        });

        // Close mobile menu on tab click
        document.querySelectorAll('.navbar-tab').forEach(function(btn) {
            btn.addEventListener('click', function() {
                var tabs = document.querySelector('.navbar-tabs');
                if (tabs) tabs.classList.remove('mobile-open');
            });
        });

    }

    function handleHash(hash) {
        if (!hash) hash = 'overview';

        // Direct tab name
        if (MAIN_TABS.indexOf(hash) !== -1) {
            activateTab(hash);
            window.scrollTo({ top: 0 });
            return;
        }

        // Check entity prefix mapping
        for (var prefix in MAIN_ENTITY_MAP) {
            if (hash.indexOf(prefix) === 0 || hash === prefix.replace('-', '') + 's') {
                activateTab(MAIN_ENTITY_MAP[prefix]);
                scrollToEntity(hash);
                updateGraphHighlight(hash);
                return;
            }
        }

        // Fallback: try to find element by ID in any panel
        var el = document.getElementById(hash);
        if (el) {
            var panel = el.closest('.tab-panel');
            if (panel) {
                var tabId = panel.id.replace('panel-', '');
                activateTab(tabId);
                scrollToEntity(hash);
                return;
            }
        }

        // Default
        activateTab('overview');
    }

    function activateTab(tabId) {
        if (MAIN_TABS.indexOf(tabId) === -1) return;
        currentTab = tabId;

        // Update regular tab buttons
        document.querySelectorAll('.navbar-tab:not(.navbar-dropdown-trigger)').forEach(function(btn) {
            btn.setAttribute('aria-selected', btn.dataset.tab === tabId ? 'true' : 'false');
        });

        // Update dropdown trigger highlight (selected if active tab is in appendix)
        var dropdownTrigger = document.querySelector('.navbar-dropdown-trigger');
        if (dropdownTrigger) {
            var isAppendixTab = APPENDIX_TABS.indexOf(tabId) !== -1;
            dropdownTrigger.setAttribute('aria-selected', isAppendixTab ? 'true' : 'false');
        }

        // Update panels
        document.querySelectorAll('.tab-panel').forEach(function(panel) {
            var isActive = panel.id === 'panel-' + tabId;
            panel.classList.toggle('active', isActive);
        });

        // Notify section nav of tab change
        document.dispatchEvent(new CustomEvent('tabactivated', { detail: { tab: tabId } }));
    }

    function scrollToEntity(entityId) {
        requestAnimationFrame(function() {
            var el = document.getElementById(entityId);
            if (el) {
                var pos = el.getBoundingClientRect().top + window.pageYOffset - CONFIG.scrollOffset;
                window.scrollTo({ top: pos, behavior: 'smooth' });
                flashHighlight(el);
            }
        });
    }

    function showEntityDetail(entityId) {
        var detailZone = document.getElementById('entity-detail');
        var entity = document.getElementById(entityId);
        if (entity && detailZone) {
            // Clone entity content into detail zone
            var clone = entity.cloneNode(true);
            clone.removeAttribute('id'); // Prevent duplicate IDs
            detailZone.innerHTML = '';
            detailZone.appendChild(clone);
        }
    }

    function flashHighlight(el) {
        el.classList.add('highlight-flash');
        setTimeout(function() { el.classList.remove('highlight-flash'); }, 1500);
    }

    function updateGraphHighlight(entityId) {
        if (window.GraphView && window.GraphView.highlightNode) {
            window.GraphView.highlightNode(entityId);
        }
    }

    function throttle(func, limit) {
        var inThrottle;
        return function() {
            var args = arguments;
            var context = this;
            if (!inThrottle) {
                func.apply(context, args);
                inThrottle = true;
                setTimeout(function() { inThrottle = false; }, limit);
            }
        };
    }

    // Export for other IIFEs (init called by LoadingProgress orchestrator)
    window.TabRouter = {
        init: init,
        activateTab: activateTab,
        scrollToEntity: scrollToEntity,
        showEntityDetail: showEntityDetail,
        handleHash: handleHash,
        updateGraphHighlight: updateGraphHighlight,
        MAIN_ENTITY_MAP: MAIN_ENTITY_MAP
    };

})();


// ============================================================
// SectionNav — Persistent left nav with per-tab scroll-spy
// ============================================================
(function() {
    'use strict';

    var currentTab = null;
    var observer = null;
    var boundClickHandlers = new WeakSet();

    function init() {
        // Listen for tab changes from TabRouter
        document.addEventListener('tabactivated', function(e) {
            activateNavGroup(e.detail.tab);
        });

        // Activate initial tab (overview is default)
        activateNavGroup('overview');
    }

    function activateNavGroup(tabId) {
        if (tabId === currentTab) return;
        currentTab = tabId;

        // Show the correct nav group, hide others
        document.querySelectorAll('.section-nav-items').forEach(function(group) {
            group.classList.toggle('active', group.dataset.tab === tabId);
        });

        // Restart scroll-spy for the new tab
        startScrollSpy(tabId);

        // Init collapsible nav groups for findings/claims
        initCollapsibleNav(tabId);
    }

    function startScrollSpy(tabId) {
        // Disconnect previous observer
        if (observer) {
            observer.disconnect();
            observer = null;
        }

        var group = document.querySelector('.section-nav-items[data-tab="' + tabId + '"]');
        if (!group) return;

        var links = group.querySelectorAll('.section-nav-link');
        if (!links.length) return;

        // Clear all active states
        links.forEach(function(l) { l.classList.remove('active'); });

        // Build target map
        var sections = [];
        links.forEach(function(link) {
            var href = link.getAttribute('href');
            if (href && href.charAt(0) === '#') {
                var target = document.getElementById(href.slice(1));
                if (target) sections.push({ link: link, target: target });
            }
        });

        if (!sections.length) return;

        // Bind click handlers (only once per link element)
        links.forEach(function(link) {
            if (boundClickHandlers.has(link)) return;
            boundClickHandlers.add(link);
            link.addEventListener('click', function(e) {
                e.preventDefault();
                var href = link.getAttribute('href');
                var target = document.getElementById(href.slice(1));
                if (target) {
                    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    // Update active state in current group
                    var parentGroup = link.closest('.section-nav-items');
                    if (parentGroup) {
                        parentGroup.querySelectorAll('.section-nav-link').forEach(function(l) {
                            l.classList.remove('active');
                        });
                    }
                    link.classList.add('active');
                }
            });
        });

        // Activate first link immediately
        if (sections[0]) sections[0].link.classList.add('active');

        // IntersectionObserver scroll-spy
        observer = new IntersectionObserver(function(entries) {
            var intersecting = entries.filter(function(e) { return e.isIntersecting; });
            if (!intersecting.length) return;
            var topmost = intersecting.reduce(function(best, e) {
                return (!best || e.boundingClientRect.top < best.boundingClientRect.top) ? e : best;
            }, null);
            if (!topmost) return;
            links.forEach(function(l) { l.classList.remove('active'); });
            var match = sections.find(function(s) { return s.target === topmost.target; });
            if (match) {
                match.link.classList.add('active');
                ensureNavLinkVisible(match.link);
            }
        }, {
            rootMargin: '-80px 0px -55% 0px',
            threshold: 0
        });

        sections.forEach(function(s) { observer.observe(s.target); });
    }

    function initCollapsibleNav(tabId) {
        if (tabId !== 'findings' && tabId !== 'claims') return;

        var group = document.querySelector('.section-nav-items[data-tab="' + tabId + '"]');
        if (!group) return;

        var headers = group.querySelectorAll('.section-nav-dimension, .section-nav-question');
        headers.forEach(function(header) {
            if (boundClickHandlers.has(header)) return;
            boundClickHandlers.add(header);
            header.addEventListener('click', function(e) {
                // Don't toggle when clicking a nav link — let it navigate
                if (e.target.closest('.section-nav-link')) return;
                var parent = header.closest('.nav-dim-group, .nav-q-group');
                if (parent) parent.classList.toggle('collapsed');
            });
        });
    }

    function ensureNavLinkVisible(link) {
        // Expand any collapsed parent groups so the active link is visible
        var qGroup = link.closest('.nav-q-group');
        if (qGroup) qGroup.classList.remove('collapsed');
        var dimGroup = link.closest('.nav-dim-group');
        if (dimGroup) dimGroup.classList.remove('collapsed');
        // Scroll sidebar to keep active link in view
        link.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }

    window.SectionNav = { init: init };
})();


// ============================================================
// EntityFocusTracker — Tracks which entity is visible in main
// panel and updates GraphView local graph accordingly
// ============================================================
(function() {
    'use strict';

    var entityObserver = null;
    var currentFocusId = null;

    function init() {
        // Listen for tab changes to re-observe entity sections
        document.addEventListener('tabactivated', function(e) {
            observeEntities(e.detail.tab);
        });

        // Start observing initial tab
        observeEntities('overview');
    }

    function observeEntities(tabId) {
        if (entityObserver) {
            entityObserver.disconnect();
            entityObserver = null;
        }

        var panel = document.getElementById('panel-' + tabId);
        if (!panel) return;

        var sections = panel.querySelectorAll('.entity-section');
        if (!sections.length) return;

        entityObserver = new IntersectionObserver(function(entries) {
            var visible = entries.filter(function(e) { return e.isIntersecting; });
            if (!visible.length) return;

            // Pick the topmost visible entity section
            var topmost = visible.reduce(function(best, e) {
                return (!best || e.boundingClientRect.top < best.boundingClientRect.top) ? e : best;
            }, null);

            if (!topmost) return;
            var entityId = topmost.target.id;
            if (entityId && entityId !== currentFocusId) {
                currentFocusId = entityId;
                // Update graph to show local connections of this entity
                if (window.GraphView && window.GraphView.focusEntity) {
                    window.GraphView.focusEntity(entityId);
                }
                // Show entity display text in detail panel
                showFocusedEntityDisplay(entityId);
            }
        }, {
            rootMargin: '-80px 0px -60% 0px',
            threshold: 0
        });

        sections.forEach(function(s) { entityObserver.observe(s); });
    }

    function showFocusedEntityDisplay(entityId) {
        var detailZone = document.getElementById('entity-detail');
        if (!detailZone) return;

        // Only show the "pick entity" prompt if detail zone still has the placeholder
        // or shows the same entity that's already in focus in main panel
        var placeholder = detailZone.querySelector('.entity-detail-placeholder');
        if (placeholder) {
            // Keep showing placeholder — user hasn't picked anything in graph yet
            return;
        }
    }

    window.EntityFocusTracker = { init: init };
})();


// ============================================================
// WikilinkPreview — Obsidian-style hover previews
// ============================================================
(function() {
    'use strict';

    var CONFIG = {
        hoverDelay: 300,
        hideDelay: 200,
        previewOffset: { x: 15, y: 15 }
    };

    var showTimeout = null;
    var hideTimeout = null;
    var popup = null;

    function init() {
        popup = document.getElementById('wikilink-popup');
        if (!popup) return;

        var wikilinks = document.querySelectorAll('a.wikilink:not(.wikilink-broken)');
        wikilinks.forEach(function(link) {
            link.addEventListener('mouseenter', handleMouseEnter);
            link.addEventListener('mouseleave', handleMouseLeave);
            link.addEventListener('mousemove', handleMouseMove);
            link.addEventListener('click', handleWikilinkClick);
        });

        popup.addEventListener('mouseenter', function() { clearTimeout(hideTimeout); });
        popup.addEventListener('mouseleave', scheduleHide);
        document.addEventListener('click', hidePopup);
    }

    function handleMouseEnter(event) {
        var link = event.currentTarget;
        if (!link.dataset.preview) return;

        clearTimeout(hideTimeout);
        showTimeout = setTimeout(function() {
            showPreview(link, event);
        }, CONFIG.hoverDelay);
    }

    function handleMouseLeave() {
        clearTimeout(showTimeout);
        scheduleHide();
    }

    function handleMouseMove(event) {
        if (popup && popup.classList.contains('visible')) {
            positionPopup(event);
        }
    }

    /**
     * Handle wikilink click — routes through TabRouter for cross-panel navigation
     */
    function handleWikilinkClick(event) {
        var link = event.currentTarget;
        var href = link.getAttribute('href');
        if (!href || href.charAt(0) !== '#') return;

        event.preventDefault();
        hidePopup();

        var entityId = href.substring(1);

        // Route through TabRouter
        if (window.TabRouter) {
            window.TabRouter.handleHash(entityId);
            history.pushState(null, null, href);
        }
    }

    function scheduleHide() {
        hideTimeout = setTimeout(hidePopup, CONFIG.hideDelay);
    }

    function hidePopup() {
        clearTimeout(showTimeout);
        clearTimeout(hideTimeout);
        if (popup) {
            popup.classList.remove('visible');
            popup.classList.add('hidden');
        }
    }

    function showPreview(link, event) {
        try {
            var data = JSON.parse(link.dataset.preview);
            var entityType = link.dataset.entityType;
            renderPreview(entityType, data);
            positionPopup(event);
            popup.classList.remove('hidden');
            popup.classList.add('visible');
        } catch (error) {
            // Silently fail for malformed preview data
        }
    }

    function renderPreview(entityType, data) {
        var _t = (typeof UI_TRANSLATIONS !== 'undefined') ? UI_TRANSLATIONS : {};
        var typeLabels = {
            trend: _t.type_trend || 'Trend',
            synthesis: _t.type_synthesis || 'Dimension Synthesis',
            finding: _t.type_finding || 'Finding',
            claim: _t.type_claim || 'Claim',
            source: _t.type_source || 'Source',
            concept: _t.type_concept || 'Concept',
            megatrend: _t.type_megatrend || 'Megatrend',
            citation: _t.type_citation || 'Citation',
            dimension: _t.type_dimension || 'Dimension',
            question: _t.type_question || 'Question'
        };

        var typeBadge = popup.querySelector('.entity-type-badge');
        if (typeBadge) {
            typeBadge.textContent = typeLabels[entityType] || entityType;
            typeBadge.className = 'entity-type-badge badge-' + entityType;
        }

        var titleEl = popup.querySelector('.preview-title');
        if (titleEl) titleEl.textContent = data.title || '';

        var badgesEl = popup.querySelector('.preview-badges');
        if (badgesEl) {
            badgesEl.innerHTML = '';
            if (entityType === 'trend') {
                if (data.dimension) badgesEl.innerHTML += '<span class="badge dimension">' + escapeHtml(data.dimension) + '</span>';
                if (data.horizon) badgesEl.innerHTML += '<span class="badge horizon">' + escapeHtml(data.horizon) + '</span>';
                if (data.portfolio_count && data.portfolio_count > 0) badgesEl.innerHTML += '<span class="badge portfolio">' + data.portfolio_count + ' ' + (data.portfolio_count !== 1 ? (_t.portfolios || 'portfolios') : (_t.portfolio || 'portfolio')) + '</span>';
            } else if (entityType === 'synthesis') {
                if (data.dimension) badgesEl.innerHTML += '<span class="badge dimension">' + escapeHtml(data.dimension) + '</span>';
                if (data.trend_count) badgesEl.innerHTML += '<span class="badge trend-count">' + escapeHtml(data.trend_count) + ' trends</span>';
                if (data.avg_confidence) {
                    var confPct = Math.round(parseFloat(data.avg_confidence) * 100);
                    badgesEl.innerHTML += '<span class="badge confidence">Avg: ' + confPct + '%</span>';
                }
            }
        }

        var excerptEl = popup.querySelector('.preview-excerpt');
        var metaEl = popup.querySelector('.preview-meta');
        if (excerptEl) excerptEl.style.fontStyle = '';

        if (entityType === 'claim') {
            if (excerptEl) {
                excerptEl.textContent = '\u201C' + (data.claim_text || '') + '\u201D';
                excerptEl.style.fontStyle = 'italic';
            }
            if (metaEl) {
                var confidence = data.confidence ? Math.round(data.confidence * 100) : '?';
                var status = data.status || 'unverified';
                metaEl.innerHTML = 'Confidence: ' + confidence + '% <span class="badge status-' + status + '">' + status + '</span>';
            }
        } else if (entityType === 'finding') {
            if (excerptEl) {
                var findings = data.key_findings || data.key_trends || [];
                if (findings.length > 0) {
                    excerptEl.innerHTML = findings.map(function(i) { return '\u2022 ' + escapeHtml(i); }).join('<br>');
                } else {
                    excerptEl.textContent = data.excerpt || '';
                }
            }
            if (metaEl) metaEl.textContent = '';
        } else if (entityType === 'source') {
            if (excerptEl) {
                var badges = '';
                if (data.source_type) badges += '<span class="badge source-type">' + escapeHtml(data.source_type) + '</span> ';
                if (data.tier) badges += '<span class="badge tier">' + escapeHtml(data.tier) + '</span>';
                excerptEl.innerHTML = badges || (_t.type_source || 'Source');
            }
            if (metaEl) metaEl.textContent = data.domain || '';
        } else if (entityType === 'citation') {
            if (excerptEl) {
                excerptEl.textContent = '\u201C' + (data.quote || '') + '\u201D';
                excerptEl.style.fontStyle = 'italic';
            }
            if (metaEl) {
                var meta = data.source_ref || '';
                if (data.page) meta += ', p. ' + data.page;
                metaEl.textContent = meta;
            }
        } else if (entityType === 'synthesis') {
            if (excerptEl) excerptEl.textContent = data.excerpt || '';
            if (metaEl) metaEl.textContent = data.word_count ? data.word_count + ' words' : '';
        } else {
            if (excerptEl) excerptEl.textContent = data.excerpt || '';
            if (metaEl) metaEl.textContent = '';
        }
    }

    function positionPopup(event) {
        if (!popup) return;
        var x = event.clientX + CONFIG.previewOffset.x;
        var y = event.clientY + CONFIG.previewOffset.y;
        var rect = popup.getBoundingClientRect();
        var vw = window.innerWidth;
        var vh = window.innerHeight;

        if (x + rect.width > vw - 20) x = event.clientX - rect.width - CONFIG.previewOffset.x;
        if (y + rect.height > vh - 20) y = event.clientY - rect.height - CONFIG.previewOffset.y;
        x = Math.max(10, x);
        y = Math.max(10, y);

        popup.style.left = x + 'px';
        popup.style.top = y + 'px';
    }

    window.WikilinkPreview = { init: init, hidePopup: hidePopup };
})();


// ============================================================
// KanbanBoard — Trend Landscape kanban grid
// ============================================================
(function() {
    'use strict';

    var CONFIG = { hoverDelay: 200, hideDelay: 150 };
    var kanbanData = null;
    var showTimeout = null;
    var hideTimeout = null;

    function initKanban() {
        if (typeof RADAR_DATA === 'undefined' || !RADAR_DATA) { hideKanbanSection(); return; }
        kanbanData = RADAR_DATA;
        if (!kanbanData.dataPoints || kanbanData.dataPoints.length === 0) { hideKanbanSection(); return; }
        renderBoard();
        attachEventListeners();
    }

    function hideKanbanSection() {
        var section = document.getElementById('kanban-section');
        if (section) section.style.display = 'none';
    }

    function groupDataPoints() {
        var groups = {};
        kanbanData.dataPoints.forEach(function(point) {
            var key = (point.dimension || '_none') + '|' + (point.horizon || 'plan');
            if (!groups[key]) groups[key] = [];
            groups[key].push(point);
        });
        return groups;
    }

    function renderBoard() {
        var container = document.getElementById('kanban-body');
        if (!container || !kanbanData.dimensions) return;

        var groups = groupDataPoints();
        var horizons = ['act', 'plan', 'observe'];

        kanbanData.dimensions.forEach(function(dim) {
            var row = document.createElement('div');
            row.className = 'kanban-row';
            row.setAttribute('data-dimension', dim.slug || dim.id);

            var rowHeader = document.createElement('div');
            rowHeader.className = 'kanban-row-header';
            rowHeader.textContent = dim.title || dim.id;
            row.appendChild(rowHeader);

            horizons.forEach(function(horizon) {
                var cell = document.createElement('div');
                cell.className = 'kanban-cell';
                cell.setAttribute('data-horizon', horizon);

                var key = (dim.slug || dim.id) + '|' + horizon;
                (groups[key] || []).forEach(function(point) {
                    cell.appendChild(createCard(point));
                });

                row.appendChild(cell);
            });

            container.appendChild(row);
        });

        // Undimensioned items
        var undimensioned = [];
        horizons.forEach(function(horizon) {
            var key = '_none|' + horizon;
            if (groups[key]) {
                groups[key].forEach(function(p) {
                    undimensioned.push({ point: p, horizon: horizon });
                });
            }
        });

        if (undimensioned.length > 0) {
            var row = document.createElement('div');
            row.className = 'kanban-row';
            row.setAttribute('data-dimension', '_none');

            var rowHeader = document.createElement('div');
            rowHeader.className = 'kanban-row-header';
            rowHeader.textContent = (kanbanData.translations && kanbanData.translations.general) || 'General';
            row.appendChild(rowHeader);

            horizons.forEach(function(horizon) {
                var cell = document.createElement('div');
                cell.className = 'kanban-cell';
                cell.setAttribute('data-horizon', horizon);
                undimensioned.forEach(function(item) {
                    if (item.horizon === horizon) cell.appendChild(createCard(item.point));
                });
                row.appendChild(cell);
            });

            container.appendChild(row);
        }
    }

    function createCard(point) {
        var card = document.createElement('div');
        card.className = 'kanban-card';
        card.setAttribute('data-id', point.id);
        card.setAttribute('data-type', point.type);
        card.setAttribute('data-preview', JSON.stringify(point.preview || {}));
        card.setAttribute('tabindex', '0');
        card.setAttribute('role', 'button');
        card.setAttribute('aria-label', point.title);

        var typeDot = document.createElement('span');
        typeDot.className = 'card-type ' + point.type;
        card.appendChild(typeDot);

        var titleSpan = document.createElement('span');
        titleSpan.className = 'card-title';
        titleSpan.textContent = point.title || point.id;
        titleSpan.setAttribute('title', point.title || point.id);
        card.appendChild(titleSpan);

        return card;
    }

    function attachEventListeners() {
        document.querySelectorAll('.kanban-card').forEach(function(card) {
            card.addEventListener('mouseenter', handleCardHover);
            card.addEventListener('mouseleave', handleCardLeave);
            card.addEventListener('click', handleCardClick);
            card.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); handleCardClick(e); }
            });
        });
    }

    function handleCardHover(event) {
        clearTimeout(hideTimeout);
        var card = event.currentTarget;
        showTimeout = setTimeout(function() {
            var preview = {};
            try { preview = JSON.parse(card.dataset.preview || '{}'); } catch (e) { /* ignore */ }

            var popup = document.getElementById('wikilink-popup');
            if (!popup) return;

            renderCardPreview(popup, card.dataset.type, preview);
            positionPopupNearCard(popup, card);
            popup.classList.remove('hidden');
            popup.classList.add('visible');
        }, CONFIG.hoverDelay);
    }

    function handleCardLeave() {
        clearTimeout(showTimeout);
        hideTimeout = setTimeout(function() {
            var popup = document.getElementById('wikilink-popup');
            if (popup) { popup.classList.remove('visible'); popup.classList.add('hidden'); }
        }, CONFIG.hideDelay);
    }

    /**
     * Handle card click — routes through TabRouter
     */
    function handleCardClick(event) {
        var card = event.currentTarget;
        var entityId = card.dataset.id;

        var popup = document.getElementById('wikilink-popup');
        if (popup) { popup.classList.remove('visible'); popup.classList.add('hidden'); }

        if (window.TabRouter) {
            window.TabRouter.handleHash(entityId);
            history.pushState(null, null, '#' + entityId);
        }
    }

    function renderCardPreview(popup, entityType, data) {
        var badge = popup.querySelector('.entity-type-badge');
        var title = popup.querySelector('.preview-title');
        var badges = popup.querySelector('.preview-badges');
        var excerpt = popup.querySelector('.preview-excerpt');
        var meta = popup.querySelector('.preview-meta');

        var _kt = (typeof UI_TRANSLATIONS !== 'undefined') ? UI_TRANSLATIONS : {};
        var typeLabels = {
            'megatrend': _kt.type_megatrend || 'Megatrend',
            'trend': _kt.type_trend || 'Trend'
        };

        badge.textContent = typeLabels[entityType] || entityType;
        badge.className = 'entity-type-badge badge-' + entityType;
        title.textContent = data.title || '';

        var badgesHtml = '';
        if (data.dimension) badgesHtml += '<span class="badge dimension">' + escapeHtml(data.dimension) + '</span>';
        if (data.horizon || data.planning_horizon) {
            var horizon = data.horizon || data.planning_horizon;
            badgesHtml += '<span class="badge horizon ' + horizon + '">' + horizon.toUpperCase() + '</span>';
        }
        if (data.evidence_strength) badgesHtml += '<span class="badge evidence">' + escapeHtml(data.evidence_strength) + '</span>';
        if (data.confidence && typeof data.confidence === 'number') badgesHtml += '<span class="badge confidence">' + Math.round(data.confidence * 100) + '%</span>';
        if (data.portfolio_count && data.portfolio_count > 0) badgesHtml += '<span class="badge portfolio">' + data.portfolio_count + ' ' + (data.portfolio_count !== 1 ? (_kt.portfolios || 'portfolios') : (_kt.portfolio || 'portfolio')) + '</span>';
        badges.innerHTML = badgesHtml;

        var excerptText = data.excerpt || data.trend || data.megatrend_name || '';
        if (excerptText.length > 150) excerptText = excerptText.substring(0, 147) + '...';
        excerpt.textContent = excerptText;
        if (excerpt) excerpt.style.fontStyle = '';

        var metaText = '';
        if (data.finding_count) metaText += data.finding_count + ' findings';
        if (data.source_type) metaText += (metaText ? ' \u00B7 ' : '') + data.source_type;
        meta.textContent = metaText;
    }

    function positionPopupNearCard(popup, card) {
        var rect = card.getBoundingClientRect();
        var left = rect.right + 10;
        var top = rect.top;
        var vw = window.innerWidth;
        var vh = window.innerHeight;

        if (left + 320 > vw - 20) left = rect.left - 320 - 10;
        if (top + 200 > vh - 20) top = vh - 200 - 20;
        left = Math.max(10, left);
        top = Math.max(10, top);

        popup.style.left = left + 'px';
        popup.style.top = top + 'px';
    }

    window.KanbanBoard = { init: initKanban };
})();


// ============================================================
// GraphView — D3 local graph (Obsidian-style) for focused entity
// ============================================================
(function() {
    'use strict';

    var _initialized = false;
    var _d3 = null;
    var _simulation = null;
    var _svg = null;
    var _g = null;
    var _zoom = null;
    var _container = null;
    var _currentFocus = null;
    var _visibleTypes = {};

    // Full graph data (immutable reference)
    var _allNodes = [];
    var _allLinks = [];
    var _nodeMap = {};       // id -> node data
    var _adjacency = {};     // id -> Set of neighbor ids

    // Node colors by entity type
    var TYPE_COLORS = {
        'synthesis': '#00b8d4',
        'megatrend': '#ff6b4a',
        'trend': '#0d3c55',
        'concept': '#5b2c6f',
        'claim': '#27ae60',
        'finding': '#1a5276',
        'source': '#b7950b',
        'citation': '#5a7a8a',
        'question': '#00b8d4',
        'dimension': '#0d3c55',
        'initial-question': '#0d3c55',
        'publisher': '#8e6f3e',
        'query-batch': '#6c757d'
    };

    // Node sizes by entity type (center node gets boosted)
    var TYPE_SIZES = {
        'synthesis': 14,
        'megatrend': 11,
        'trend': 9,
        'concept': 6,
        'claim': 5,
        'finding': 5,
        'source': 4,
        'citation': 3,
        'question': 4,
        'dimension': 7,
        'initial-question': 5,
        'publisher': 4,
        'query-batch': 4
    };

    function init() {
        if (_initialized) return;

        _container = document.getElementById('graph-container');
        if (!_container) { if (window.LoadingProgress) window.LoadingProgress.step('Graph view'); return; }
        if (typeof GRAPH_DATA === 'undefined' || !GRAPH_DATA) {
            renderFallback('No graph data available');
            if (window.LoadingProgress) window.LoadingProgress.step('Graph view');
            return;
        }
        if (!GRAPH_DATA.nodes || GRAPH_DATA.nodes.length === 0) {
            renderFallback('No entities to display');
            if (window.LoadingProgress) window.LoadingProgress.step('Graph view');
            return;
        }

        _initialized = true;

        // Build lookup structures from full graph data
        _allNodes = GRAPH_DATA.nodes;
        _allLinks = GRAPH_DATA.links;
        _allNodes.forEach(function(n) { _nodeMap[n.id] = n; });
        buildAdjacency();

        // Try loading D3 from CDN
        loadD3().then(function(d3) {
            _d3 = d3;
            initSvg();
            setupControls();
            // Show empty state until an entity is focused
            showEmptyGraph();
            if (window.LoadingProgress) window.LoadingProgress.step('Graph view');
        }).catch(function(err) {
            console.error('D3 loading failed:', err);
            renderFallback('Graph requires internet connection');
            if (window.LoadingProgress) window.LoadingProgress.step('Graph view');
        });
    }

    function buildAdjacency() {
        _adjacency = {};
        _allNodes.forEach(function(n) { _adjacency[n.id] = new Set(); });
        _allLinks.forEach(function(l) {
            var s = l.source, t = l.target;
            if (_adjacency[s]) _adjacency[s].add(t);
            if (_adjacency[t]) _adjacency[t].add(s);
        });
    }

    function loadD3() {
        return import('https://cdn.jsdelivr.net/npm/d3@7/+esm').then(function(module) {
            return module;
        });
    }

    function initSvg() {
        var d3 = _d3;
        var width = _container.clientWidth || 400;
        var height = _container.clientHeight || 300;

        _svg = d3.select(_container).append('svg')
            .attr('width', '100%')
            .attr('height', '100%')
            .attr('viewBox', '0 0 ' + width + ' ' + height);

        _g = _svg.append('g');
        _zoom = d3.zoom()
            .scaleExtent([0.3, 5])
            .on('zoom', function(event) { _g.attr('transform', event.transform); });
        _svg.call(_zoom);
    }

    function showEmptyGraph() {
        if (!_g) return;
        _g.selectAll('*').remove();
        if (_simulation) { _simulation.stop(); _simulation = null; }

        var _kt = (typeof UI_TRANSLATIONS !== 'undefined') ? UI_TRANSLATIONS : {};
        var msg = _kt.graph_empty_state || 'Scroll to an entity to see its connections';

        var width = _container.clientWidth || 400;
        var height = _container.clientHeight || 300;
        _g.append('text')
            .attr('x', width / 2)
            .attr('y', height / 2)
            .attr('text-anchor', 'middle')
            .attr('fill', 'var(--color-text-muted)')
            .attr('font-size', '0.8rem')
            .text(msg);
    }

    /**
     * Focus the local graph on a specific entity (Obsidian local graph style).
     * Shows only the focused entity + its direct neighbors + connecting edges.
     */
    function focusEntity(entityId) {
        if (!_d3 || !_svg || !_g) return;
        if (!_nodeMap[entityId]) return;
        if (entityId === _currentFocus) return;
        _currentFocus = entityId;

        var d3 = _d3;

        // Collect local neighborhood: center + direct neighbors
        var neighborIds = _adjacency[entityId] || new Set();
        var localIds = new Set(neighborIds);
        localIds.add(entityId);

        // Apply type filter
        var filteredIds = new Set();
        localIds.forEach(function(id) {
            var n = _nodeMap[id];
            if (!n) return;
            // Always include the center node; filter neighbors by type toggle
            if (id === entityId || _visibleTypes[n.type] !== false) {
                filteredIds.add(id);
            }
        });

        // Build local nodes (deep copy, D3 mutates)
        var nodes = [];
        filteredIds.forEach(function(id) {
            var n = _nodeMap[id];
            if (n) nodes.push(Object.assign({}, n, { isCenter: id === entityId }));
        });

        // Build local links
        var links = [];
        _allLinks.forEach(function(l) {
            if (filteredIds.has(l.source) && filteredIds.has(l.target)) {
                links.push({ source: l.source, target: l.target, type: l.type });
            }
        });

        // No connections? Show node alone with message
        if (nodes.length <= 1) {
            renderLocalGraph(nodes, [], entityId);
            return;
        }

        renderLocalGraph(nodes, links, entityId);
    }

    function renderLocalGraph(nodes, links, centerId) {
        var d3 = _d3;
        var width = _container.clientWidth || 400;
        var height = _container.clientHeight || 300;

        // Clear previous
        _g.selectAll('*').remove();
        if (_simulation) { _simulation.stop(); _simulation = null; }

        // Reset zoom
        _svg.call(_zoom.transform, d3.zoomIdentity);

        if (nodes.length === 0) {
            showEmptyGraph();
            return;
        }

        // Force simulation — center node pinned at center
        _simulation = d3.forceSimulation(nodes)
            .force('link', d3.forceLink(links).id(function(d) { return d.id; }).distance(70))
            .force('charge', d3.forceManyBody().strength(-200))
            .force('center', d3.forceCenter(width / 2, height / 2))
            .force('collision', d3.forceCollide().radius(function(d) {
                var base = d.isCenter ? (TYPE_SIZES[d.type] || 5) * 1.5 : (TYPE_SIZES[d.type] || 5);
                return base + 4;
            }));

        // Pin center node
        nodes.forEach(function(n) {
            if (n.id === centerId) {
                n.fx = width / 2;
                n.fy = height / 2;
            }
        });

        // Links
        var link = _g.append('g').selectAll('line')
            .data(links)
            .join('line')
            .attr('class', 'graph-link')
            .attr('stroke', 'var(--color-border)')
            .attr('stroke-opacity', 0.4)
            .attr('stroke-width', 1);

        // Nodes
        var node = _g.append('g').selectAll('g')
            .data(nodes)
            .join('g')
            .attr('class', function(d) {
                return 'graph-node' + (d.isCenter ? ' graph-node-center' : '');
            })
            .call(d3.drag()
                .on('start', function(event, d) {
                    if (!event.active) _simulation.alphaTarget(0.3).restart();
                    d.fx = d.x; d.fy = d.y;
                })
                .on('drag', function(event, d) {
                    d.fx = event.x; d.fy = event.y;
                })
                .on('end', function(event, d) {
                    if (!event.active) _simulation.alphaTarget(0);
                    // Keep center node pinned
                    if (!d.isCenter) { d.fx = null; d.fy = null; }
                }));

        // Center node: larger with accent ring
        node.append('circle')
            .attr('r', function(d) {
                return d.isCenter ? (TYPE_SIZES[d.type] || 5) * 1.6 : (TYPE_SIZES[d.type] || 5);
            })
            .attr('fill', function(d) { return TYPE_COLORS[d.type] || '#999'; })
            .attr('stroke', function(d) {
                return d.isCenter ? 'var(--color-accent)' : 'var(--color-bg-primary)';
            })
            .attr('stroke-width', function(d) { return d.isCenter ? 3 : 1.5; });

        // Labels for all nodes
        node.append('text')
            .attr('dy', function(d) {
                var r = d.isCenter ? (TYPE_SIZES[d.type] || 5) * 1.6 : (TYPE_SIZES[d.type] || 5);
                return r + 12;
            })
            .attr('text-anchor', 'middle')
            .attr('fill', function(d) {
                return d.isCenter ? 'var(--color-text-primary)' : 'var(--color-text-secondary)';
            })
            .attr('font-size', function(d) { return d.isCenter ? '0.7rem' : '0.6rem'; })
            .attr('font-weight', function(d) { return d.isCenter ? '600' : '400'; })
            .attr('class', function(d) { return d.isCenter ? '' : 'graph-node-label'; })
            .attr('pointer-events', 'none')
            .text(function(d) {
                var t = d.title || d.id;
                var max = d.isCenter ? 28 : 20;
                return t.length > max ? t.substring(0, max - 3) + '...' : t;
            });

        // Tooltips
        node.append('title').text(function(d) { return d.title || d.id; });

        // Hover: dim non-hovered, highlight edges
        node.on('mouseenter', function(event, d) {
            if (d.isCenter) return; // center is always highlighted
            var hoveredId = d.id;
            node.classed('dimmed', function(n) {
                return n.id !== hoveredId && !n.isCenter;
            });
            link.classed('dimmed', function(l) {
                var sId = typeof l.source === 'object' ? l.source.id : l.source;
                var tId = typeof l.target === 'object' ? l.target.id : l.target;
                return !(sId === hoveredId || tId === hoveredId);
            });
            link.classed('highlighted', function(l) {
                var sId = typeof l.source === 'object' ? l.source.id : l.source;
                var tId = typeof l.target === 'object' ? l.target.id : l.target;
                return sId === hoveredId || tId === hoveredId;
            });
        })
        .on('mouseleave', function() {
            node.classed('dimmed', false);
            link.classed('dimmed', false);
            link.classed('highlighted', false);
        })
        .on('click', function(event, d) {
            // Click neighbor: show its detail in bottom panel
            if (window.TabRouter) {
                window.TabRouter.showEntityDetail(d.id);
            }
        });

        // Tick
        _simulation.on('tick', function() {
            link
                .attr('x1', function(d) { return d.source.x; })
                .attr('y1', function(d) { return d.source.y; })
                .attr('x2', function(d) { return d.target.x; })
                .attr('y2', function(d) { return d.target.y; });
            node.attr('transform', function(d) { return 'translate(' + d.x + ',' + d.y + ')'; });
        });
    }

    function highlightNode(entityId) {
        // In local graph mode, focusing the entity replaces the old highlight behavior
        focusEntity(entityId);
    }

    function setupControls() {
        var toggleContainer = document.getElementById('graph-filter-toggles');

        if (toggleContainer && _d3) {
            // Determine which types exist in the data
            var typesPresent = {};
            GRAPH_DATA.nodes.forEach(function(n) { typesPresent[n.type] = true; });

            // Ordered type list (most important first)
            var typeOrder = ['synthesis', 'megatrend', 'trend', 'concept', 'claim',
                             'finding', 'source', 'citation', 'question', 'dimension',
                             'publisher', 'query-batch', 'initial-question'];

            // All types visible initially
            typeOrder.forEach(function(t) { if (typesPresent[t]) _visibleTypes[t] = true; });

            // Labels from embedded translation data
            var labels = (typeof GRAPH_TYPE_LABELS !== 'undefined') ? GRAPH_TYPE_LABELS : {};

            // Build toggle checkboxes
            var html = '';
            typeOrder.forEach(function(type) {
                if (!typesPresent[type]) return;
                var color = TYPE_COLORS[type] || '#999';
                var label = labels[type] || type;
                html += '<label class="graph-type-toggle">' +
                    '<input type="checkbox" checked data-type="' + type + '">' +
                    '<span class="graph-toggle-dot" style="background:' + color + '"></span>' +
                    '<span class="graph-toggle-label">' + label + '</span>' +
                    '</label>';
            });
            toggleContainer.innerHTML = html;

            // Handle checkbox changes — re-render local graph with new filter
            toggleContainer.addEventListener('change', function(e) {
                if (e.target.type !== 'checkbox') return;
                var type = e.target.getAttribute('data-type');
                _visibleTypes[type] = e.target.checked;
                if (_currentFocus) {
                    // Force re-render by clearing current focus
                    var prev = _currentFocus;
                    _currentFocus = null;
                    focusEntity(prev);
                }
            });
        }

    }

    function renderFallback(message) {
        var el = _container ? _container.querySelector('.graph-fallback') : null;
        if (!el && _container) {
            el = document.createElement('div');
            el.className = 'graph-fallback';
            _container.appendChild(el);
        }
        if (el) el.textContent = message;
    }

    // Do NOT init on load — lazy init when panel opens
    window.GraphView = {
        init: init,
        highlightNode: highlightNode,
        focusEntity: focusEntity,
        _initialized: false,
        get initialized() { return _initialized; }
    };

    Object.defineProperty(window.GraphView, '_initialized', {
        get: function() { return _initialized; }
    });

})();


// ============================================================
// LandingPage — Landing page transition to report
// ============================================================
(function() {
    'use strict';

    function init() {
        var lp = document.querySelector('.landing-page');
        if (!lp) return;

        // Event delegation on landing page container — more robust than per-element binding
        lp.addEventListener('click', function(e) {
            // Walk up from click target to find .lp-enter-report
            var el = e.target;
            while (el && el !== lp) {
                if (el.classList && el.classList.contains('lp-enter-report')) {
                    e.preventDefault();
                    e.stopPropagation();
                    var hash = el.getAttribute('href') || el.getAttribute('data-target') || '#overview';
                    enterReport(hash);
                    return;
                }
                el = el.parentElement;
            }
        });

        // Escape key enters report
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && document.body.classList.contains('landing-mode')) {
                enterReport('#overview');
            }
        });

        // Navbar brand as "home" button — click + keyboard
        var brand = document.querySelector('.navbar-brand.has-landing');
        if (brand) {
            brand.addEventListener('click', function() {
                if (!document.body.classList.contains('landing-mode')) {
                    returnToLanding();
                }
            });
            brand.addEventListener('keydown', function(e) {
                if ((e.key === 'Enter' || e.key === ' ') && !document.body.classList.contains('landing-mode')) {
                    e.preventDefault();
                    returnToLanding();
                }
            });
        }
    }

    function enterReport(targetHash) {
        // Fade out landing page
        document.body.classList.add('landing-exit');

        setTimeout(function() { // Landing transition: 400ms — must match report-layout.css .landing-exit
            // Remove landing mode — shows report
            document.body.classList.remove('landing-mode');
            document.body.classList.remove('landing-exit');

            // Trigger report init via LoadingProgress (runs if not yet started)
            if (window.LoadingProgress && window.LoadingProgress.run) {
                window.LoadingProgress.run();
            }

            // Navigate to target tab after a brief yield for init
            setTimeout(function() {
                if (targetHash && targetHash !== '#') {
                    window.location.hash = targetHash;
                    if (window.TabRouter && window.TabRouter.handleHash) {
                        window.TabRouter.handleHash();
                    }
                }
            }, 100);
        }, 400);
    }

    function returnToLanding() {
        // Reverse of enterReport: fade landing page back in
        document.body.classList.add('landing-enter');
        document.body.classList.add('landing-mode');

        setTimeout(function() { // Landing transition: 400ms — must match report-layout.css .landing-enter
            document.body.classList.remove('landing-enter');
        }, 400);
    }

    // Auto-init
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    window.LandingPage = { init: init, enterReport: enterReport, returnToLanding: returnToLanding };
})();


// ============================================================
// PanelToggle — Right panel expand/collapse with state persistence
// ============================================================
(function() {
    'use strict';

    var STORAGE_KEY = 'report-panel-collapsed';

    function init() {
        var toggle = document.getElementById('panel-toggle');
        var panel = document.querySelector('.right-panel');
        if (!toggle || !panel) return;

        // Restore saved state
        try {
            if (localStorage.getItem(STORAGE_KEY) === '1') {
                collapse(panel);
            }
        } catch (e) { /* localStorage unavailable */ }

        toggle.addEventListener('click', function() {
            if (panel.classList.contains('collapsed')) {
                expand(panel);
            } else {
                collapse(panel);
            }
        });

        // Rail icons expand panel on click
        var railIcons = panel.querySelectorAll('.panel-rail-icon');
        for (var i = 0; i < railIcons.length; i++) {
            railIcons[i].addEventListener('click', function() {
                expand(panel);
            });
        }
    }

    function collapse(panel) {
        panel.classList.add('collapsed');
        document.body.classList.add('panel-collapsed');
        try { localStorage.setItem(STORAGE_KEY, '1'); } catch (e) {}
    }

    function expand(panel) {
        panel.classList.remove('collapsed');
        document.body.classList.remove('panel-collapsed');
        try { localStorage.setItem(STORAGE_KEY, '0'); } catch (e) {}
        // Re-trigger graph layout if it was initialized
        if (window.GraphView && window.GraphView._initialized) {
            setTimeout(function() {
                var svg = panel.querySelector('svg');
                if (svg) {
                    var evt = new Event('resize');
                    window.dispatchEvent(evt);
                }
            }, 300);
        }
    }

    // Auto-init after DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    window.PanelToggle = { init: init };
})();
