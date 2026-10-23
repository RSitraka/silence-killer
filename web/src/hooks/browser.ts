import { useEffect, useRef } from 'react';

/**
 * Garde l'écran allumé tant que [active] est vrai (API Screen Wake Lock).
 * Le verrou saute quand l'onglet est caché : on le redemande au retour.
 */
export function useWakeLock(active: boolean) {
  useEffect(() => {
    if (!active || !('wakeLock' in navigator)) return;
    let lock: WakeLockSentinel | null = null;
    let cancelled = false;

    const request = async () => {
      try {
        const l = await navigator.wakeLock.request('screen');
        if (cancelled) l.release().catch(() => {});
        else lock = l;
      } catch {
        /* refusé (batterie faible, onglet caché…) : tant pis */
      }
    };
    const onVisible = () => {
      if (document.visibilityState === 'visible') request();
    };

    request();
    document.addEventListener('visibilitychange', onVisible);
    return () => {
      cancelled = true;
      document.removeEventListener('visibilitychange', onVisible);
      lock?.release().catch(() => {});
    };
  }, [active]);
}

/**
 * Intercepte le bouton / geste « retour » du navigateur : au lieu de quitter
 * la page, [onBack] est appelé. Un état d'historique factice est ré-empilé à
 * chaque retour pour que le suivant soit aussi intercepté.
 */
export function useBackButton(onBack: () => void) {
  const handler = useRef(onBack);
  handler.current = onBack;

  useEffect(() => {
    history.pushState({ clinDoeil: true }, '');
    const onPop = () => {
      history.pushState({ clinDoeil: true }, '');
      handler.current();
    };
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
}

/** Demande confirmation avant de fermer / recharger l'onglet si [active]. */
export function useConfirmLeave(active: boolean) {
  useEffect(() => {
    if (!active) return;
    const onBeforeUnload = (e: BeforeUnloadEvent) => {
      e.preventDefault();
      e.returnValue = '';
    };
    window.addEventListener('beforeunload', onBeforeUnload);
    return () => window.removeEventListener('beforeunload', onBeforeUnload);
  }, [active]);
}

/** Appelle [onHidden] dès que l'onglet passe en arrière-plan. */
export function useOnHidden(onHidden: () => void) {
  const handler = useRef(onHidden);
  handler.current = onHidden;
  useEffect(() => {
    const onChange = () => {
      if (document.visibilityState === 'hidden') handler.current();
    };
    document.addEventListener('visibilitychange', onChange);
    window.addEventListener('pagehide', onChange);
    return () => {
      document.removeEventListener('visibilitychange', onChange);
      window.removeEventListener('pagehide', onChange);
    };
  }, []);
}
