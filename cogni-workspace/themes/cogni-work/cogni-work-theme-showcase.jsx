import { useState } from "react";

const theme = {
  primary: "#111111",
  secondary: "#333333",
  accent: "#C8E62E",
  accentMuted: "#A8C424",
  accentDark: "#8BA31E",
  bg: "#FAFAF8",
  surface: "#F2F2EE",
  surfaceDark: "#111111",
  text: "#111111",
  textLight: "#FFFFFF",
  textMuted: "#6B7280",
  border: "#E0E0DC",
  success: "#2E7D32",
  warning: "#E5A100",
  danger: "#D32F2F",
  info: "#1565C0",
};

const fontLink = document.createElement("link");
fontLink.href =
  "https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&family=JetBrains+Mono:wght@400;500&display=swap";
fontLink.rel = "stylesheet";
document.head.appendChild(fontLink);

const s = {
  font: "'DM Sans', 'Inter', 'Calibri', sans-serif",
  mono: "'JetBrains Mono', 'Fira Code', 'Consolas', monospace",
};

/* ─── Tiny Icon Components ─── */
const IconZap = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
);
const IconCheck = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
);
const IconArrow = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
);
const IconStar = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
);
const IconMenu = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="15" y2="12"/><line x1="3" y1="18" x2="18" y2="18"/></svg>
);

/* ─── Section Wrapper ─── */
const Section = ({ title, dark, children, style }) => (
  <div
    style={{
      background: dark ? theme.surfaceDark : theme.bg,
      padding: "48px 40px",
      ...style,
    }}
  >
    <div
      style={{
        fontSize: 11,
        fontWeight: 600,
        letterSpacing: "0.12em",
        textTransform: "uppercase",
        color: dark ? theme.accent : theme.textMuted,
        marginBottom: 8,
        fontFamily: s.mono,
      }}
    >
      {title}
    </div>
    {children}
  </div>
);

/* ─── Main Component ─── */
export default function CogniWorkThemeShowcase() {
  const [activeTab, setActiveTab] = useState(0);
  const [toggle, setToggle] = useState(true);
  const [sliderVal, setSliderVal] = useState(65);
  const [selectedCard, setSelectedCard] = useState(1);
  const tabs = ["Overview", "Components", "Patterns"];

  return (
    <div
      style={{
        fontFamily: s.font,
        color: theme.text,
        background: theme.bg,
        minHeight: "100vh",
        maxWidth: 960,
        margin: "0 auto",
      }}
    >
      {/* ═══ HERO — Dark Anchor ═══ */}
      <div
        style={{
          background: theme.surfaceDark,
          padding: "56px 40px 48px",
          position: "relative",
          overflow: "hidden",
        }}
      >
        {/* Decorative grid */}
        <div style={{ position: "absolute", top: 0, left: 0, right: 0, bottom: 0, opacity: 0.04 }}>
          {Array.from({ length: 12 }).map((_, i) => (
            <div key={i} style={{ position: "absolute", left: `${(i + 1) * 80}px`, top: 0, bottom: 0, width: 1, background: theme.accent }} />
          ))}
        </div>
        <div style={{ position: "relative", zIndex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 32 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 8,
                background: theme.accent,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: theme.primary,
              }}
            >
              <IconZap />
            </div>
            <span style={{ color: theme.textLight, fontWeight: 700, fontSize: 18, letterSpacing: "-0.02em" }}>
              cogni<span style={{ color: theme.accent }}>-</span>work
            </span>
          </div>
          <h1
            style={{
              color: theme.textLight,
              fontSize: 42,
              fontWeight: 700,
              lineHeight: 1.1,
              letterSpacing: "-0.03em",
              margin: 0,
              maxWidth: 560,
            }}
          >
            Theme <span style={{ color: theme.accent }}>Showcase</span>
          </h1>
          <p
            style={{
              color: theme.textMuted,
              fontSize: 16,
              lineHeight: 1.6,
              marginTop: 16,
              maxWidth: 480,
            }}
          >
            Firmitas · Utilitas · Venustas — Vitruvius' Triade als Design-System. Elektrisches Chartreuse auf tiefem Schwarz.
          </p>
        </div>
      </div>

      {/* ═══ COLOR PALETTE ═══ */}
      <Section title="Farbpalette">
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(130px, 1fr))", gap: 12, marginTop: 16 }}>
          {[
            { name: "Primary", hex: theme.primary, light: true },
            { name: "Secondary", hex: theme.secondary, light: true },
            { name: "Accent", hex: theme.accent },
            { name: "Accent Muted", hex: theme.accentMuted },
            { name: "Accent Dark", hex: theme.accentDark },
            { name: "Background", hex: theme.bg },
            { name: "Surface", hex: theme.surface },
            { name: "Text Muted", hex: theme.textMuted, light: true },
            { name: "Border", hex: theme.border },
            { name: "Success", hex: theme.success, light: true },
            { name: "Warning", hex: theme.warning },
            { name: "Danger", hex: theme.danger, light: true },
          ].map((c) => (
            <div key={c.name} style={{ borderRadius: 10, overflow: "hidden", border: `1px solid ${theme.border}` }}>
              <div style={{ background: c.hex, height: 56 }} />
              <div style={{ padding: "8px 10px", background: "#fff" }}>
                <div style={{ fontSize: 12, fontWeight: 600, color: theme.text }}>{c.name}</div>
                <div style={{ fontSize: 11, fontFamily: s.mono, color: theme.textMuted, marginTop: 2 }}>{c.hex}</div>
              </div>
            </div>
          ))}
        </div>
      </Section>

      {/* ═══ TYPOGRAPHY ═══ */}
      <Section title="Typografie" dark>
        <div style={{ marginTop: 20 }}>
          {[
            { label: "H1", size: 42, weight: 700, ls: "-0.03em" },
            { label: "H2", size: 32, weight: 700, ls: "-0.02em" },
            { label: "H3", size: 24, weight: 600, ls: "-0.01em" },
            { label: "H4", size: 18, weight: 600, ls: "0" },
          ].map((t) => (
            <div key={t.label} style={{ display: "flex", alignItems: "baseline", gap: 20, marginBottom: 16 }}>
              <span style={{ fontFamily: s.mono, fontSize: 11, color: theme.accent, width: 28, flexShrink: 0 }}>{t.label}</span>
              <span style={{ fontSize: t.size, fontWeight: t.weight, letterSpacing: t.ls, color: theme.textLight, lineHeight: 1.2 }}>
                DM Sans {t.weight === 700 ? "Bold" : "Semibold"}
              </span>
            </div>
          ))}
          <div style={{ borderTop: `1px solid rgba(200,230,46,0.15)`, marginTop: 8, paddingTop: 16 }}>
            <div style={{ display: "flex", alignItems: "baseline", gap: 20, marginBottom: 12 }}>
              <span style={{ fontFamily: s.mono, fontSize: 11, color: theme.accent, width: 28, flexShrink: 0 }}>P</span>
              <span style={{ fontSize: 15, color: "rgba(255,255,255,0.8)", lineHeight: 1.65, maxWidth: 520 }}>
                Body-Text in DM Sans Regular — klar, lesbar, mit großzügigem Zeilenabstand. Chartreuse akzentuiert nur das Wesentliche.
              </span>
            </div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 20 }}>
              <span style={{ fontFamily: s.mono, fontSize: 11, color: theme.accent, width: 28, flexShrink: 0 }}>{"</>"}</span>
              <span style={{ fontFamily: s.mono, fontSize: 13, color: theme.accent, opacity: 0.8 }}>
                JetBrains Mono — Code & Monospace
              </span>
            </div>
          </div>
        </div>
      </Section>

      {/* ═══ BUTTONS ═══ */}
      <Section title="Buttons & Interaktionen">
        <div style={{ display: "flex", flexWrap: "wrap", gap: 12, marginTop: 16, alignItems: "center" }}>
          {/* Primary CTA */}
          <button
            style={{
              background: theme.accent,
              color: theme.primary,
              border: "none",
              borderRadius: 8,
              padding: "12px 24px",
              fontSize: 14,
              fontWeight: 600,
              fontFamily: s.font,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: 8,
              transition: "background 0.2s",
            }}
            onMouseEnter={(e) => (e.target.style.background = theme.accentMuted)}
            onMouseLeave={(e) => (e.target.style.background = theme.accent)}
          >
            Primär-CTA <IconArrow />
          </button>
          {/* Secondary */}
          <button
            style={{
              background: "transparent",
              color: theme.text,
              border: `1.5px solid ${theme.primary}`,
              borderRadius: 8,
              padding: "11px 24px",
              fontSize: 14,
              fontWeight: 600,
              fontFamily: s.font,
              cursor: "pointer",
            }}
          >
            Sekundär
          </button>
          {/* Ghost */}
          <button
            style={{
              background: "transparent",
              color: theme.textMuted,
              border: `1.5px solid ${theme.border}`,
              borderRadius: 8,
              padding: "11px 24px",
              fontSize: 14,
              fontWeight: 500,
              fontFamily: s.font,
              cursor: "pointer",
            }}
          >
            Ghost
          </button>
          {/* Dark CTA */}
          <button
            style={{
              background: theme.primary,
              color: theme.textLight,
              border: "none",
              borderRadius: 8,
              padding: "12px 24px",
              fontSize: 14,
              fontWeight: 600,
              fontFamily: s.font,
              cursor: "pointer",
            }}
          >
            Dark
          </button>
          {/* Small */}
          <button
            style={{
              background: theme.accent,
              color: theme.primary,
              border: "none",
              borderRadius: 6,
              padding: "7px 14px",
              fontSize: 12,
              fontWeight: 600,
              fontFamily: s.font,
              cursor: "pointer",
            }}
          >
            Klein
          </button>
        </div>

        {/* Toggle + Slider */}
        <div style={{ display: "flex", gap: 32, marginTop: 28, alignItems: "center", flexWrap: "wrap" }}>
          {/* Toggle */}
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <span style={{ fontSize: 13, color: theme.textMuted }}>Toggle</span>
            <div
              onClick={() => setToggle(!toggle)}
              style={{
                width: 44,
                height: 24,
                borderRadius: 12,
                background: toggle ? theme.accent : theme.border,
                cursor: "pointer",
                position: "relative",
                transition: "background 0.25s",
              }}
            >
              <div
                style={{
                  width: 18,
                  height: 18,
                  borderRadius: 9,
                  background: "#fff",
                  position: "absolute",
                  top: 3,
                  left: toggle ? 23 : 3,
                  transition: "left 0.25s",
                  boxShadow: "0 1px 3px rgba(0,0,0,0.2)",
                }}
              />
            </div>
          </div>
          {/* Slider */}
          <div style={{ display: "flex", alignItems: "center", gap: 10, flex: 1, minWidth: 200 }}>
            <span style={{ fontSize: 13, color: theme.textMuted }}>Slider</span>
            <div style={{ flex: 1, position: "relative", height: 6, borderRadius: 3, background: theme.border }}>
              <div style={{ width: `${sliderVal}%`, height: "100%", borderRadius: 3, background: theme.accent, transition: "width 0.1s" }} />
              <input
                type="range"
                min={0}
                max={100}
                value={sliderVal}
                onChange={(e) => setSliderVal(+e.target.value)}
                style={{
                  position: "absolute",
                  top: -8,
                  left: 0,
                  width: "100%",
                  height: 20,
                  opacity: 0,
                  cursor: "pointer",
                }}
              />
              <div
                style={{
                  position: "absolute",
                  left: `calc(${sliderVal}% - 8px)`,
                  top: -5,
                  width: 16,
                  height: 16,
                  borderRadius: 8,
                  background: theme.accent,
                  border: "2px solid #fff",
                  boxShadow: "0 1px 4px rgba(0,0,0,0.15)",
                  pointerEvents: "none",
                }}
              />
            </div>
            <span style={{ fontFamily: s.mono, fontSize: 12, color: theme.accent, width: 32, textAlign: "right" }}>{sliderVal}%</span>
          </div>
        </div>
      </Section>

      {/* ═══ TABS ═══ */}
      <Section title="Navigation & Tabs" style={{ background: theme.surface }}>
        {/* Navbar mock */}
        <div
          style={{
            background: theme.primary,
            borderRadius: 10,
            padding: "14px 20px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            marginTop: 16,
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{ width: 26, height: 26, borderRadius: 6, background: theme.accent, display: "flex", alignItems: "center", justifyContent: "center", color: theme.primary }}>
              <IconZap />
            </div>
            <span style={{ color: theme.textLight, fontWeight: 600, fontSize: 14 }}>cogni-work</span>
          </div>
          <div style={{ display: "flex", gap: 24, alignItems: "center" }}>
            {["Projekte", "Kunden", "Berichte"].map((item, i) => (
              <span
                key={item}
                style={{
                  color: i === 0 ? theme.accent : "rgba(255,255,255,0.55)",
                  fontSize: 13,
                  fontWeight: i === 0 ? 600 : 400,
                  cursor: "pointer",
                }}
              >
                {item}
              </span>
            ))}
            <div style={{ color: "rgba(255,255,255,0.6)", cursor: "pointer" }}>
              <IconMenu />
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div style={{ display: "flex", gap: 0, marginTop: 20, borderBottom: `2px solid ${theme.border}` }}>
          {tabs.map((tab, i) => (
            <button
              key={tab}
              onClick={() => setActiveTab(i)}
              style={{
                background: "none",
                border: "none",
                borderBottom: activeTab === i ? `2px solid ${theme.accent}` : "2px solid transparent",
                marginBottom: -2,
                padding: "10px 20px",
                fontSize: 13,
                fontWeight: activeTab === i ? 600 : 400,
                color: activeTab === i ? theme.text : theme.textMuted,
                cursor: "pointer",
                fontFamily: s.font,
                transition: "all 0.2s",
              }}
            >
              {tab}
            </button>
          ))}
        </div>
        <div style={{ padding: "16px 0", fontSize: 14, color: theme.textMuted, lineHeight: 1.6 }}>
          Aktiver Tab: <strong style={{ color: theme.text }}>{tabs[activeTab]}</strong> — Inhalte werden hier angezeigt.
        </div>
      </Section>

      {/* ═══ CARDS ═══ */}
      <Section title="Karten & Panels">
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", gap: 16, marginTop: 16 }}>
          {[
            { title: "Firmitas", desc: "Dunkle Strukturanker geben Stabilität und Fundament.", metric: "98%", sub: "Solidität" },
            { title: "Utilitas", desc: "Maximaler Kontrast für klare Lesbarkeit und Funktion.", metric: "4.5:1", sub: "Kontrast" },
            { title: "Venustas", desc: "Chartreuse als Signatur — mutig, einprägsam, unverwechselbar.", metric: "#C8E62E", sub: "Accent" },
          ].map((card, i) => (
            <div
              key={card.title}
              onClick={() => setSelectedCard(i)}
              style={{
                background: "#fff",
                border: selectedCard === i ? `2px solid ${theme.accent}` : `1px solid ${theme.border}`,
                borderRadius: 12,
                padding: 24,
                cursor: "pointer",
                transition: "all 0.2s",
                boxShadow: selectedCard === i ? `0 0 0 3px rgba(200,230,46,0.15)` : "none",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <h3 style={{ margin: 0, fontSize: 17, fontWeight: 700, letterSpacing: "-0.01em" }}>{card.title}</h3>
                {selectedCard === i && <span style={{ color: theme.accent }}><IconCheck /></span>}
              </div>
              <p style={{ fontSize: 13, color: theme.textMuted, lineHeight: 1.55, margin: "10px 0 16px" }}>{card.desc}</p>
              <div style={{ borderTop: `1px solid ${theme.border}`, paddingTop: 12, display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
                <span style={{ fontFamily: s.mono, fontSize: 18, fontWeight: 700, color: theme.accent }}>{card.metric}</span>
                <span style={{ fontSize: 11, color: theme.textMuted, textTransform: "uppercase", letterSpacing: "0.06em" }}>{card.sub}</span>
              </div>
            </div>
          ))}
        </div>
      </Section>

      {/* ═══ STATUS BADGES + TABLE ═══ */}
      <Section title="Status & Daten" dark>
        {/* Badges */}
        <div style={{ display: "flex", gap: 10, marginTop: 16, flexWrap: "wrap" }}>
          {[
            { label: "Aktiv", bg: "rgba(46,125,50,0.15)", color: theme.success },
            { label: "Warnung", bg: "rgba(229,161,0,0.15)", color: theme.warning },
            { label: "Fehler", bg: "rgba(211,47,47,0.15)", color: theme.danger },
            { label: "Info", bg: "rgba(21,101,192,0.15)", color: theme.info },
            { label: "Neu", bg: "rgba(200,230,46,0.12)", color: theme.accent },
          ].map((b) => (
            <span
              key={b.label}
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 6,
                background: b.bg,
                color: b.color,
                fontSize: 12,
                fontWeight: 600,
                padding: "5px 12px",
                borderRadius: 6,
              }}
            >
              <span style={{ width: 6, height: 6, borderRadius: 3, background: b.color }} />
              {b.label}
            </span>
          ))}
        </div>

        {/* Mini Data Table */}
        <div style={{ marginTop: 24, borderRadius: 10, overflow: "hidden", border: "1px solid rgba(255,255,255,0.08)" }}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
            <thead>
              <tr style={{ background: "rgba(255,255,255,0.04)" }}>
                {["Projekt", "Status", "Score", "Trend"].map((h) => (
                  <th
                    key={h}
                    style={{
                      textAlign: "left",
                      padding: "10px 16px",
                      fontSize: 11,
                      fontWeight: 600,
                      textTransform: "uppercase",
                      letterSpacing: "0.08em",
                      color: theme.accent,
                      fontFamily: s.mono,
                      borderBottom: "1px solid rgba(255,255,255,0.06)",
                    }}
                  >
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {[
                { name: "cogni-claims", status: "Aktiv", statusColor: theme.success, score: 94, trend: "+12%" },
                { name: "cogni-portfolio", status: "In Arbeit", statusColor: theme.warning, score: 78, trend: "+5%" },
                { name: "trend-scout", status: "Planung", statusColor: theme.info, score: 62, trend: "Neu" },
              ].map((row) => (
                <tr key={row.name} style={{ borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
                  <td style={{ padding: "12px 16px", color: theme.textLight, fontWeight: 500 }}>{row.name}</td>
                  <td style={{ padding: "12px 16px" }}>
                    <span style={{ display: "inline-flex", alignItems: "center", gap: 6, color: row.statusColor, fontSize: 12 }}>
                      <span style={{ width: 6, height: 6, borderRadius: 3, background: row.statusColor }} />
                      {row.status}
                    </span>
                  </td>
                  <td style={{ padding: "12px 16px" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <div style={{ width: 60, height: 5, borderRadius: 3, background: "rgba(255,255,255,0.08)" }}>
                        <div style={{ width: `${row.score}%`, height: "100%", borderRadius: 3, background: theme.accent }} />
                      </div>
                      <span style={{ fontFamily: s.mono, fontSize: 12, color: theme.accent }}>{row.score}</span>
                    </div>
                  </td>
                  <td style={{ padding: "12px 16px", fontFamily: s.mono, fontSize: 12, color: row.trend.startsWith("+") ? theme.accent : theme.textMuted }}>
                    {row.trend}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Section>

      {/* ═══ METRICS ROW ═══ */}
      <Section title="KPI Dashboard">
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: 16, marginTop: 16 }}>
          {[
            { label: "Revenue", value: "€128K", change: "+18%", up: true },
            { label: "Kunden", value: "47", change: "+6", up: true },
            { label: "NPS Score", value: "72", change: "-3", up: false },
            { label: "Projekte", value: "12", change: "3 aktiv", up: null },
          ].map((kpi) => (
            <div
              key={kpi.label}
              style={{
                background: "#fff",
                border: `1px solid ${theme.border}`,
                borderRadius: 10,
                padding: "20px 20px 16px",
              }}
            >
              <div style={{ fontSize: 11, fontWeight: 500, color: theme.textMuted, textTransform: "uppercase", letterSpacing: "0.06em" }}>{kpi.label}</div>
              <div style={{ fontSize: 28, fontWeight: 700, color: theme.text, letterSpacing: "-0.02em", marginTop: 6 }}>{kpi.value}</div>
              <div
                style={{
                  fontSize: 12,
                  fontWeight: 600,
                  fontFamily: s.mono,
                  marginTop: 6,
                  color: kpi.up === true ? theme.success : kpi.up === false ? theme.danger : theme.textMuted,
                }}
              >
                {kpi.change}
              </div>
            </div>
          ))}
        </div>
      </Section>

      {/* ═══ FORM ELEMENTS ═══ */}
      <Section title="Formulare" style={{ background: theme.surface }}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, marginTop: 16, maxWidth: 560 }}>
          <div>
            <label style={{ fontSize: 12, fontWeight: 600, color: theme.text, display: "block", marginBottom: 6 }}>Name</label>
            <input
              placeholder="Stephan de Haas"
              style={{
                width: "100%",
                padding: "10px 14px",
                borderRadius: 8,
                border: `1.5px solid ${theme.border}`,
                fontSize: 14,
                fontFamily: s.font,
                background: "#fff",
                outline: "none",
                boxSizing: "border-box",
              }}
              onFocus={(e) => (e.target.style.borderColor = theme.accent)}
              onBlur={(e) => (e.target.style.borderColor = theme.border)}
            />
          </div>
          <div>
            <label style={{ fontSize: 12, fontWeight: 600, color: theme.text, display: "block", marginBottom: 6 }}>E-Mail</label>
            <input
              placeholder="stephan@cogni-work.ai"
              style={{
                width: "100%",
                padding: "10px 14px",
                borderRadius: 8,
                border: `1.5px solid ${theme.border}`,
                fontSize: 14,
                fontFamily: s.font,
                background: "#fff",
                outline: "none",
                boxSizing: "border-box",
              }}
              onFocus={(e) => (e.target.style.borderColor = theme.accent)}
              onBlur={(e) => (e.target.style.borderColor = theme.border)}
            />
          </div>
          <div style={{ gridColumn: "1 / -1" }}>
            <label style={{ fontSize: 12, fontWeight: 600, color: theme.text, display: "block", marginBottom: 6 }}>Nachricht</label>
            <textarea
              placeholder="Ihre Anfrage..."
              rows={3}
              style={{
                width: "100%",
                padding: "10px 14px",
                borderRadius: 8,
                border: `1.5px solid ${theme.border}`,
                fontSize: 14,
                fontFamily: s.font,
                background: "#fff",
                outline: "none",
                resize: "vertical",
                boxSizing: "border-box",
              }}
              onFocus={(e) => (e.target.style.borderColor = theme.accent)}
              onBlur={(e) => (e.target.style.borderColor = theme.border)}
            />
          </div>
        </div>
        <button
          style={{
            background: theme.accent,
            color: theme.primary,
            border: "none",
            borderRadius: 8,
            padding: "12px 28px",
            fontSize: 14,
            fontWeight: 600,
            fontFamily: s.font,
            cursor: "pointer",
            marginTop: 16,
            display: "flex",
            alignItems: "center",
            gap: 8,
          }}
        >
          Absenden <IconArrow />
        </button>
      </Section>

      {/* ═══ PRICING EXAMPLE ═══ */}
      <Section title="Pricing-Beispiel" dark>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 16, marginTop: 20 }}>
          {[
            { tier: "Starter", price: "€490", period: "/Monat", features: ["5 Projekte", "E-Mail Support", "Basis-Reports"], highlight: false },
            { tier: "Professional", price: "€990", period: "/Monat", features: ["Unbegrenzt", "Priority Support", "Custom Reports", "API Zugang"], highlight: true },
            { tier: "Enterprise", price: "Individuell", period: "", features: ["Dedicated Team", "24/7 Support", "On-Premise", "SLA"], highlight: false },
          ].map((plan) => (
            <div
              key={plan.tier}
              style={{
                background: plan.highlight ? theme.accent : "rgba(255,255,255,0.04)",
                border: plan.highlight ? "none" : "1px solid rgba(255,255,255,0.08)",
                borderRadius: 12,
                padding: 28,
                color: plan.highlight ? theme.primary : theme.textLight,
                position: "relative",
              }}
            >
              {plan.highlight && (
                <div
                  style={{
                    position: "absolute",
                    top: -1,
                    right: 16,
                    background: theme.primary,
                    color: theme.accent,
                    fontSize: 10,
                    fontWeight: 700,
                    padding: "4px 10px",
                    borderRadius: "0 0 6px 6px",
                    textTransform: "uppercase",
                    letterSpacing: "0.08em",
                  }}
                >
                  Empfohlen
                </div>
              )}
              <div style={{ fontSize: 13, fontWeight: 600, opacity: plan.highlight ? 0.7 : 0.5, textTransform: "uppercase", letterSpacing: "0.06em" }}>
                {plan.tier}
              </div>
              <div style={{ marginTop: 12, marginBottom: 20 }}>
                <span style={{ fontSize: 32, fontWeight: 700, letterSpacing: "-0.02em" }}>{plan.price}</span>
                <span style={{ fontSize: 13, opacity: 0.6 }}>{plan.period}</span>
              </div>
              {plan.features.map((f) => (
                <div key={f} style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 10, fontSize: 13 }}>
                  <span style={{ color: plan.highlight ? theme.primary : theme.accent }}>
                    <IconCheck />
                  </span>
                  <span style={{ opacity: 0.85 }}>{f}</span>
                </div>
              ))}
              <button
                style={{
                  width: "100%",
                  marginTop: 12,
                  padding: "11px 0",
                  borderRadius: 8,
                  border: plan.highlight ? `1.5px solid ${theme.primary}` : `1.5px solid rgba(200,230,46,0.4)`,
                  background: plan.highlight ? theme.primary : "transparent",
                  color: plan.highlight ? theme.accent : theme.accent,
                  fontSize: 13,
                  fontWeight: 600,
                  fontFamily: s.font,
                  cursor: "pointer",
                }}
              >
                Auswählen
              </button>
            </div>
          ))}
        </div>
      </Section>

      {/* ═══ FOOTER — Dark Anchor ═══ */}
      <div
        style={{
          background: theme.surfaceDark,
          padding: "32px 40px",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap",
          gap: 12,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <div style={{ width: 22, height: 22, borderRadius: 5, background: theme.accent, display: "flex", alignItems: "center", justifyContent: "center", color: theme.primary }}>
            <IconZap />
          </div>
          <span style={{ color: "rgba(255,255,255,0.5)", fontSize: 13 }}>
            cogni-work Theme · Firmitas · Utilitas · Venustas
          </span>
        </div>
        <div style={{ display: "flex", gap: 4, alignItems: "center" }}>
          {[1, 2, 3, 4, 5].map((n) => (
            <span key={n} style={{ color: theme.accent, opacity: n <= 4 ? 1 : 0.3 }}>
              <IconStar />
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}
