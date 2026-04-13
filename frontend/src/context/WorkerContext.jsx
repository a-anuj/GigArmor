import { createContext, useContext, useState } from 'react';

const WorkerContext = createContext(null);

export function WorkerProvider({ children }) {
    const [worker, setWorker] = useState(
        JSON.parse(localStorage.getItem('hustlehalt_worker') || 'null')
    );

    const saveWorker = (w) => {
        setWorker(w);
        localStorage.setItem('hustlehalt_worker', JSON.stringify(w));
    };

    const clearWorker = () => {
        setWorker(null);
        localStorage.removeItem('hustlehalt_worker');
    };

    return (
        <WorkerContext.Provider value={{ worker, saveWorker, clearWorker }}>
            {children}
        </WorkerContext.Provider>
    );
}

export const useWorker = () => useContext(WorkerContext);
