--1
SET SERVEROUTPUT ON
DECLARE
    CURSOR c_angajati IS
        SELECT id_angajat, nume, data_angajare from angajati 
        ORDER BY data_angajare desc;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Detalii angajati: ');
    FOR r in c_angajati LOOP
        EXIT WHEN c_angajati%ROWCOUNT > 5; --am uitat sa adaug conditia de iesire din loop
        DBMS_OUTPUT.PUT_LINE(r.id_angajat ||' ' || r.nume || ' ' || r.data_angajare);
    END LOOP;
END;

--2
SET SERVEROUTPUT ON
DECLARE
    v_vechime NUMBER(4,2);
    CURSOR c_angajati IS
        SELECT nume, id_functie, data_angajare, (SYSDATE - data_angajare) / 365 AS vechime 
        FROM angajati;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Detalii Angajati: ' );
    FOR r IN c_angajati LOOP
        EXIT WHEN r.data_angajare > TO_DATE('01-08-2016', 'DD--MM-YYYY'); 
        v_vechime := (SYSDATE - r.data_angajare) / 365; --nu mai puneam asta daca mergea to_char
        DBMS_OUTPUT.PUT_LINE(r.nume || ' ' || r.id_functie || ' ' || r.data_angajare || ' ' || v_vechime);
    END LOOP;
END;
--initial am vrut sa nu incarc intr-o alta variabila vechimea (am folosit direct TO_CHAR la select-ul de vechime din cursor), dar nu stiu de ce la unii angajati aparea 
--vechimea ca fiind #### : 
--TO_CHAR((SYS_DATE - data_angajare) / 365, '0.00') as vechime
--acum mi-am dat seama ca puteam sa folosesc round la 2 zecimale la r.vechime (in loc de v_vechime din dbms)

--3
DECLARE
    CURSOR c IS SELECT id_angajat, nume, comision, COUNT(id_comanda) as nr
    FROM angajati JOIN comenzi USING (id_angajat)
    GROUP BY id_angajat, nume, comision;
    v_comision NUMBER;
BEGIN 
    FOR v in c LOOP
        IF v.nr < 6 THEN 
            v_comision := 0.6;
        ELSIF v.nr < 10 THEN
            v_comision := 0.7;
        ELSE 
            v_comision := 0.8;
        END IF;
        
        UPDATE angajati
        SET comision = v_comision
        WHERE id_angajat =  v.id_angajat;
    END LOOP;
END;

--4 
DECLARE 
    TYPE tip is TABLE OF angajati.nume%type INDEX BY PLS_INTEGER;
    t tip; --o vb.
BEGIN 
    UPDATE angajati
    SET salariul = salariul * 2
    WHERE id_angajat IN (SELECT id_angajat FROM comenzi WHERE EXTRACT (YEAR from data) = 2009)
    RETURNING nume BULK COLLECT INTO t; 
    
    FOR i in t.FIRST..t.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(t(i));
    END LOOP;
END;


--5  ; e ca ex 6
DECLARE
    TYPE rec IS RECORD
    (id angajati.id_departament%type, denumire departamente.denumire_departament%type, sal_mediu NUMBER);
    TYPE tip IS TABLE OF rec INDEX BY PLS_INTEGER;
    t tip;
BEGIN
    SELECT id_departament, denumire_departament, ROUND(AVG(salariul),2) as medie
    BULK COLLECT INTO t
    FROM angajati  JOIN departamente  USING (id_departament)
    GROUP BY id_departament, denumire_departament;
    FOR i in t.FIRST..t.LAST LOOP
        DBMS_OUTPUT.PUT_LINE('ID departament: ' || t(i).id || ' | Nume: ' || t(i).denumire || ' | Sal. mediu: ' ||  t(i).sal_mediu);
    END LOOP;
END;

--6
DECLARE
    TYPE rec IS RECORD
    (nume clienti.nume_client%type, val_total NUMBER);
    TYPE tip IS TABLE OF rec INDEX BY PLS_INTEGER; --tip compus
    t tip; --vb compus
BEGIN
    SELECT nume_client, SUM(pret*cantitate) 
    BULK COLLECT INTO t
    FROM clienti JOIN comenzi USING (id_client)
        JOIN rand_comenzi USING (id_comanda)
    GROUP BY nume_client;
    FOR i in t.FIRST..t.Last LOOP
        DBMS_OUTPUT.PUT_LINE(t(i).nume || ' ' || t(i).val_total );
    END LOOP;
END;