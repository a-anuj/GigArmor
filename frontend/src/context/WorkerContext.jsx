import { createContext, useContext, useState } from 'react';

const WorkerContext = createContext(null);

export function WorkerProvider({ children }) {
    const [worker, setWorker] = useState(
        JSON.parse(localStorage.getItem('gigarmor_worker') || 'null')
    );

    const saveWorker = (w) => {
        setWorker(w);
        localStorage.setItem('gigarmor_worker', JSON.stringify(w));
    };

    const clearWorker = () => {
        setWorker(null);
        localStorage.removeItem('gigarmor_worker');
    };

    return (
        <WorkerContext.Provider value={{ worker, saveWorker, clearWorker }}>
            {children}
        </WorkerContext.Provider>
    );
}

export const useWorker = () => useContext(WorkerContext);
