import React, { type JSX, type ReactElement } from "react";

import { _t } from "../../../../languageHandler";
import SdkConfig from "~tchap-web/src/SdkConfig";
import TchapUrls from "~tchap-web/src/tchap/util/TchapUrls";

const TchapFooter = (): ReactElement => {
    const brandingConfig = SdkConfig.getObject("branding");
    const links = brandingConfig?.get("auth_footer_links") ?? [
        { text: "Blog", url: "https://element.io/blog" },
        { text: "Mastodon", url: "https://mastodon.matrix.org/@Element" },
        { text: "GitHub", url: "https://github.com/element-hq/element-web" },
    ];

    const authFooterLinks: JSX.Element[] = [];
    const authFooterBottomLinks: JSX.Element[] = [];

    for (const linkEntry of links) {
        if (["Modalités d'utilisation", "FAQ"].includes(linkEntry.text)) {
            authFooterBottomLinks.push(
                <li className="fr-footer__bottom-item">
                    <a
                        className="fr-footer__bottom-link"
                        target="_blank"
                        rel="noreferrer external"
                        title={linkEntry.text}
                        href={linkEntry.url}
                    >
                        {linkEntry.text}
                    </a>
                </li>,
            );
        } else {
            authFooterLinks.push(
                <li className="fr-footer__content-item">
                    <a
                        href={linkEntry.url}
                        title={linkEntry.text}
                        key={linkEntry.text}
                        target="_blank"
                        rel="noreferrer external"
                        className="fr-footer__content-link"
                    >
                        {linkEntry.text}
                    </a>
                </li>,
            );
        }
    }
    authFooterBottomLinks.push(
        <li className="fr-footer__bottom-item">
            <a
                className="fr-footer__bottom-link"
                href={TchapUrls.helpPrivacyPolicy}
                target="_blank"
                rel="noreferrer external"
            >
                Politique de confidentialité
            </a>
        </li>,
    );

    return (
        <footer className="fr-footer lasuite lasuite-footer tc_footer_wrapper" role="contentinfo" id="footer-7475">
            <div className="fr-container lasuite-container">
                {/* Challenge La Suite Numerique x 42 — Oleron, 14-18 septembre 2026.
                    Styles en ligne volontairement : evite de passer par rethemendex
                    et le pipeline CSS pour un bandeau de quelques lignes. */}
                <div
                    className="tc_hack42_banner"
                    style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "12px",
                        padding: "16px 0",
                        borderBottom: "1px solid rgba(0,0,0,0.1)",
                    }}
                >
                    {/* Logo officiel de 42. viewBox resserree sur le trace : celle du
                        fichier d origine (0 -200 960 960) laisse une large marge vide.
                        fill="currentColor" pour suivre le theme clair ou sombre. */}
                    <svg
                        viewBox="0 -60 960 650"
                        width="56"
                        height="38"
                        role="img"
                        aria-label="42"
                        fill="currentColor"
                        style={{ flexShrink: 0 }}
                    >
                        <polygon points="32,412.6 362.1,412.6 362.1,578 526.8,578 526.8,279.1 197.3,279.1 526.8,-51.1 362.1,-51.1 32,279.1" />
                        <polygon points="597.9,114.2 762.7,-51.1 597.9,-51.1" />
                        <polygon points="762.7,114.2 597.9,279.1 597.9,443.9 762.7,443.9 762.7,279.1 928,114.2 928,-51.1 762.7,-51.1" />
                        <polygon points="928,279.1 762.7,443.9 928,443.9" />
                    </svg>
                    <div>
                        <div style={{ fontWeight: 700 }}>42 | DINUM challenge septembre 2026</div>
                        <div style={{ fontSize: "0.9em", opacity: 0.7 }}>
                            par cdutel, lnunez, matorgue, gmarquis et michen
                        </div>
                    </div>
                </div>
                <div className="fr-footer__body">
                    <div className="fr-footer__brand">
                        <p className="fr-logo">
                            République
                            <br />
                            Française
                        </p>
                    </div>
                    <div className="fr-footer__content">
                        <p className="fr-footer__content-desc"> {_t("footer|code_source")} </p>
                        <ul className="fr-footer__content-list">
                            {authFooterLinks}
                            <li className="fr-footer__content-item">
                                <a
                                    href="https://matrix.org"
                                    target="_blank"
                                    title="matrix.org"
                                    id="footer__content-link-7366"
                                    rel="noreferrer external"
                                    className="fr-footer__content-link"
                                >
                                    {_t("powered_by_matrix")}
                                </a>
                            </li>
                        </ul>
                    </div>
                </div>
                <div className="fr-footer__bottom">
                    <ul className="fr-footer__bottom-list">{authFooterBottomLinks}</ul>
                </div>
            </div>
        </footer>
    );
};

export default TchapFooter;
