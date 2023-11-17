// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    event ProposalCreated(uint256 id);
    event VoteCast(uint256 id, address voter);

    struct Voice {
        bool isVote;
        bool voice;
    }

    struct Proposal {
        address target;
        bytes data;
        uint128 yesCount;
        uint128 noCount;
        mapping(address => Voice) voices;
        bool isExecute;
    }

    Proposal[] public proposals;
    address[] approvedAccounts;

    constructor(address[] memory _approvedAccounts) {
        approvedAccounts = _approvedAccounts;
        approvedAccounts.push(msg.sender);
    }

    modifier onlyApprovedAccounts(address account) {
        require(isApprovedAccount(account));
        _;
    }

    function newProposal(address _target, bytes calldata _data) external onlyApprovedAccounts(msg.sender) {
        Proposal storage proposal = proposals.push();
        proposal.target = _target;
        proposal.data = _data;

        emit ProposalCreated(proposals.length - 1);
    }

    function castVote(uint256 id, bool _voice) external onlyApprovedAccounts(msg.sender) {
        Proposal storage proposal = proposals[id];

        if (proposal.voices[msg.sender].isVote && proposal.voices[msg.sender].voice != _voice) {
            proposal.voices[msg.sender].voice = _voice;
            if (_voice) {
                proposal.yesCount++;
                proposal.noCount--;
            } else {
                proposal.noCount++;
                proposal.yesCount--;
            }
        } else if (!proposal.voices[msg.sender].isVote) {
            proposal.voices[msg.sender].isVote = true;
            if (_voice) {
                proposal.yesCount++;
                proposal.voices[msg.sender].voice = true;
            } else {
                proposal.noCount++;
            }
        }

        if (needExecute(id)) {
            execute(id);
        }

        emit VoteCast(id, msg.sender);
    }

    function isApprovedAccount(address _account) internal view returns (bool) {
        for (uint256 i = 0; i < approvedAccounts.length; i++) {
            if (_account == approvedAccounts[i]) {
                return true;
            }
        }
        return false;
    }

    function needExecute(uint256 _id) private view returns (bool) {
        if (proposals[_id].yesCount >= 10 && !proposals[_id].isExecute) {
            return true;
        }
        return false;
    }

    function execute(uint256 _id) private {
        (bool success,) = proposals[_id].target.call(proposals[_id].data);
        require(success);
    }
}
