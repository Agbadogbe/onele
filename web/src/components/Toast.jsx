import { createContext, useCallback, useContext, useState } from 'react';
import { IconAlert, IconCheck } from './Icons';

const ToastContext = createContext(null);

export function ToastProvider({ children }) {
  const [toast, setToast] = useState(null);

  const notify = useCallback((message, type = 'success') => {
    setToast({ message, type, id: Date.now() });
    setTimeout(() => setToast(null), 3400);
  }, []);

  return (
    <ToastContext.Provider value={notify}>
      {children}
      {toast && (
        <div className={`toast ${toast.type === 'error' ? 'error' : 'success'}`} key={toast.id} role="status">
          {toast.type === 'error' ? <IconAlert size={16} /> : <IconCheck size={16} />}
          {toast.message}
        </div>
      )}
    </ToastContext.Provider>
  );
}

export function useToast() {
  return useContext(ToastContext);
}
