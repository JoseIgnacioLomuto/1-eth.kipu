// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubastaJose {
    address public beneficiario;
    address public propietario;
    uint256 public tiempoFinSubasta;

    struct Oferta {
        address postor;
        uint256 cantidad;
    }

    Oferta[] public ofertas;
    mapping(address => uint256) public depositosAcumulados;

    bool public finalizada;

    event OfertaAceptada(address indexed postor, uint256 cantidad);
    event SubastaFinalizada(address ganador, uint256 cantidad);

    modifier soloPropietario() {
        require(msg.sender == propietario, "Solo el propietario puede llamar a esta funcion.");
        _;
    }

    modifier soloDuranteSubasta() {
        require(block.timestamp <= tiempoFinSubasta, "La subasta ya ha finalizado.");
        _;
    }

    modifier soloDespuesDeSubasta() {
        require(block.timestamp > tiempoFinSubasta, "La subasta aun no ha finalizado.");
        _;
    }

    modifier noFinalizada() {
        require(!finalizada, "La subasta ya ha finalizado.");
        _;
    }

    constructor(uint256 _tiempoSubasta, address _beneficiario) {
        propietario = msg.sender;
        beneficiario = _beneficiario;
        tiempoFinSubasta = block.timestamp + _tiempoSubasta;
        finalizada = false;
    }

    function ofertar() public payable soloDuranteSubasta {
        require(msg.value > 0, "La oferta debe ser mayor a cero.");

        ofertas.push(Oferta({
            postor: msg.sender,
            cantidad: msg.value
        }));

        depositosAcumulados[msg.sender] += msg.value;

        emit OfertaAceptada(msg.sender, msg.value);

        // Extender la subasta si se recibe una oferta en los últimos minutos
        if (block.timestamp > tiempoFinSubasta - 5 minutes) {
            tiempoFinSubasta += 5 minutes;
        }
    }

    function retirar() public returns (bool) {
        uint256 cantidad = depositosAcumulados[msg.sender];
        if (cantidad > 0) {
            uint256 penalidad = cantidad / 10; // Penalidad del 10%
            depositosAcumulados[msg.sender] = 0;

            if (!payable(msg.sender).send(cantidad - penalidad)) {
                depositosAcumulados[msg.sender] = cantidad;
                return false;
            }
        }
        return true;
    }

    function finalizarSubasta() public soloDespuesDeSubasta noFinalizada soloPropietario {
        finalizada = true;
        Oferta memory mejorOferta;

        for (uint i = 0; i < ofertas.length; i++) {
            if (ofertas[i].cantidad > mejorOferta.cantidad) {
                mejorOferta = ofertas[i];
            }
        }

        emit SubastaFinalizada(mejorOferta.postor, mejorOferta.cantidad);

        payable(beneficiario).transfer(mejorOferta.cantidad);
    }

    function mostrarGanador() public view soloDespuesDeSubasta returns (address, uint256) {
        Oferta memory mejorOferta;

        for (uint i = 0; i < ofertas.length; i++) {
            if (ofertas[i].cantidad > mejorOferta.cantidad) {
                mejorOferta = ofertas[i];
            }
        }

        return (mejorOferta.postor, mejorOferta.cantidad);
    }

    function mostrarOfertas() public view returns (Oferta[] memory) {
        return ofertas;
    }

    function tiempoRestante() public view returns (uint256) {
        if (block.timestamp >= tiempoFinSubasta) {
            return 0;
        } else {
            return tiempoFinSubasta - block.timestamp;
        }
    }
}
