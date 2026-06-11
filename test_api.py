# Prueba unitaria básica para el pipeline de ParTaxí

def calcular_comision(valor_viaje):
    # Regla de negocio: Descontar exactamente el 20% de comisión
    return valor_viaje * 0.20

def test_calculo_comision_exacto():
    # Si un viaje cuesta 10,000, la comisión debe ser 2,000
    resultado = calcular_comision(10000)
    assert resultado == 2000